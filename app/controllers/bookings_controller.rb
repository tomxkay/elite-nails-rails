# Native on-site booking flow backed by the Square Bookings API (Phase D2).
# GET /book renders the wizard; availability + create are called by the
# `booking` Stimulus controller as JSON.
class BookingsController < ApplicationController
  include RateLimiter

  # Hidden form field no human sees or fills. If it arrives populated, the
  # request is an automated submission — drop it before touching Square.
  HONEYPOT_FIELD = :website

  # Generous per-IP caps: high enough that real customers (even several on one
  # shared mobile/office IP) never hit them, low enough to stop an automated
  # flood. Throttling fails open if the cache is down (see RateLimiter).
  before_action :throttle_availability, only: %i[availability availability_options next_availability]
  before_action :throttle_create,       only: :create
  before_action :reject_honeypot,       only: :create

  # GET /book
  def show
    unless SquareApi.configured?
      redirect_to(ENV["BOOKING_URL"].presence || root_path, allow_other_host: true)
      return
    end

    @services = with_menu_descriptions(SquareApi.services)
    # Staff list is optional ("Anyone available" works without it) — e.g. it
    # 401s until the Square account finishes Appointments onboarding.
    @staff = begin
      enrich_bookable_staff(SquareApi.bookable_staff)
    rescue SquareApi::Error
      []
    end

    @preselected_service_id = params[:service_id].presence || match_service_id(params[:service_name])
    @preselected_team_member_id = params[:team_member_id].presence
    @preselected_date = parse_date(params[:date]) || Date.current

    track_event("book_page_opened", service_count: @services.size, staff_count: @staff.size) if @services.any?
  rescue SquareApi::Error => e
    @error = e.message
    @services = []
    @staff = []
  end

  # GET /book/availability?service_id=&service_version=&date=YYYY-MM-DD&team_member_id=
  def availability
    date = parse_date(params[:date]) || Date.current
    window_start = [ date.in_time_zone.beginning_of_day, Time.current + 30.minutes ].max
    window_end = date.in_time_zone.end_of_day

    slots = SquareApi.availability(
      service_variation_id: params.require(:service_id),
      start_at: window_start.utc,
      end_at: window_end.utc,
      team_member_id: params[:team_member_id].presence
    )
    render json: { slots: only_bookable_slots(slots) }
  rescue ActionController::ParameterMissing
    render json: { error: "Pick a service first" }, status: :unprocessable_entity
  rescue SquareApi::Error => e
    render json: { error: e.message }, status: :bad_gateway
  end

  # GET /book/availability/options
  def availability_options
    return render_square_unavailable unless SquareApi.configured?

    payload = Rails.cache.fetch(availability_options_cache_key, expires_in: 5.minutes) do
      services = SquareApi.services
      staff = begin
        SquareApi.bookable_staff
      rescue SquareApi::Error
        []
      end
      { services: services, staff: staff }
    end

    render json: payload
  rescue SquareApi::Error => e
    render json: { error: e.message }, status: :bad_gateway
  end

  # GET /book/availability/next?service_id=&date=&days=
  def next_availability
    return render_square_unavailable unless SquareApi.configured?

    service_id = params.require(:service_id).to_s
    date = params[:date].present? ? parse_date(params[:date]) : Date.current
    return render_invalid_availability_date unless date

    days = params[:days].presence&.to_i || 14
    days = days.clamp(1, 14)
    return render_invalid_availability_date if date < Date.current

    slots = Rails.cache.fetch(
      next_availability_cache_key(service_id: service_id, date: date, days: days),
      expires_in: 30.seconds
    ) do
      window_start = [ date.in_time_zone.beginning_of_day, Time.current + 30.minutes ].max
      window_end = (date + (days - 1).days).in_time_zone.end_of_day
      SquareApi.availability(
        service_variation_id: service_id,
        start_at: window_start.utc,
        end_at: window_end.utc
      )
    end

    staff = cached_bookable_staff
    # Square's availability search returns slots for every team member ASSIGNED
    # to the service variation — including ones whose booking profile isn't
    # bookable. "Anyone available" must only reflect staff who actually take
    # online bookings, or it advertises a time nobody can serve (e.g. a 10am
    # from a non-bookable tech when the only bookable tech opens at noon).
    #
    # ⚠️ The per-technician split below is correct only while ONE tech is
    # bookable. With two+, Square's one-tech-per-slot tagging makes per-tech
    # `next_slot` unreliable — query per tech instead. See the "Before a SECOND
    # technician becomes bookable" section in docs/booking-adoption-notes.md.
    bookable_slots = slots_for_staff(slots, staff)
    slots_by_staff = bookable_slots.group_by { |slot| slot[:team_member_id].to_s }
    technicians = staff.map do |member|
      slot = earliest_slot(slots_by_staff[member[:id].to_s])
      {
        id: member[:id],
        name: member[:name],
        next_slot: serialize_availability_slot(slot)
      }
    end

    render json: {
      technicians: technicians,
      anyone_next_slot: serialize_availability_slot(earliest_slot(bookable_slots)),
      start_date: date.iso8601,
      days: days
    }
  rescue ActionController::ParameterMissing
    render json: { error: "Choose a service first" }, status: :unprocessable_entity
  rescue SquareApi::Error => e
    render json: { error: e.message }, status: :bad_gateway
  end

  # POST /book
  def create
    idempotency_key = params.require(:idempotency_key)
    team_member_id = params.require(:team_member_id).to_s
    # Server-side guard: the client picks a slot from availability, but never
    # trust it to only send bookable techs. Square's create_booking will happily
    # book a team member who's assigned to the service but not bookable online,
    # so reject anyone outside the bookable set here. Skipped only when the set
    # can't be determined (Square staff lookup failed), where Square remains the
    # backstop.
    unless team_member_bookable?(team_member_id)
      return render json: { ok: false, error: "That technician isn't available for online booking. Please pick another time." },
                    status: :unprocessable_entity
    end

    track_event("booking_submitted", service_id: params[:service_id])
    customer = SquareApi.upsert_customer(
      given_name: params.require(:name),
      phone: params.require(:phone),
      email: params[:email].presence
    )
    booking = SquareApi.create_booking(
      customer_id: customer["id"],
      start_at: params.require(:start_at),
      service_variation_id: params.require(:service_id),
      service_variation_version: params.require(:service_version),
      team_member_id: team_member_id,
      idempotency_key: idempotency_key,
      note: params[:note].presence
    )
    track_event(
      "booking_completed",
      service_id: params[:service_id],
      team_member_id: params[:team_member_id],
      has_email: params[:email].present?
    )
    render json: { ok: true, booking: { id: booking["id"], start_at: booking["start_at"], status: booking["status"] } }
  rescue ActionController::ParameterMissing => e
    render json: { ok: false, error: "Missing required field: #{e.param}" }, status: :unprocessable_entity
  rescue SquareApi::Error => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def throttle_availability
    throttle(scope: "book:availability", limit: 60, period: 1.minute)
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  # Best-effort match of a marketing name (home-page Service/PricingItem title)
  # to a Square catalog service, so ?service_name= deep links can preselect
  # step 1. Marketing names and catalog names are maintained independently, so
  # match loosely: exact, then substring, then shared words. An unmatched name
  # just leaves the wizard unselected.
  def match_service_id(name)
    query = normalize_service_name(name)
    return nil if query.blank?

    candidates = @services.map { |service| [ service[:id], normalize_service_name(service[:name]) ] }

    exact = candidates.find { |_, candidate| candidate == query }
    return exact.first if exact

    partial = candidates.find { |_, candidate| candidate.include?(query) || query.include?(candidate) }
    return partial.first if partial

    query_tokens = query.split
    id, overlap = candidates
      .map { |candidate_id, candidate| [ candidate_id, (candidate.split & query_tokens).size ] }
      .max_by(&:last)
    overlap.to_i.positive? ? id : nil
  end

  def normalize_service_name(name)
    name.to_s.downcase.gsub(/[^a-z0-9\s]/, " ").split.map { |token| token.chomp("s") }.join(" ")
  end

  # Square's own catalog description wins, but a service imported without one
  # would leave step 1 with nothing but a name and a price — and that step is
  # where nearly all booking drop-off happens. Backfill from the site's menu
  # copy (PricingItem#description), matched on the same normalized name used
  # for deep links.
  def with_menu_descriptions(services)
    lookup = PricingItem.visible
      .where.not(description: [ nil, "" ])
      .index_by { |item| normalize_service_name(item.name) }
    return services if lookup.empty?

    services.map do |service|
      next service if service[:description].present?

      match = lookup[normalize_service_name(service[:name])]
      match ? service.merge(description: match.description) : service
    end
  end

  # Square decides which team members can be booked online. TeamMember only
  # decorates those rows with local profile content for the booking UI.
  def enrich_bookable_staff(staff)
    local_team = TeamMember.for_display
    by_name = local_team.index_by { |member| normalize_staff_name(member.name) }
    by_first_name = local_team.group_by { |member| first_staff_name(member.name) }

    staff.map do |member|
      local = matching_team_member(member[:name], by_name, by_first_name)
      display_name = local&.name.presence || member[:name]

      member.merge(
        square_name: member[:name],
        name: display_name,
        role: local&.role,
        bio: local&.bio,
        quote: local&.quote,
        specialties: local&.specialties || [],
        image: local&.image
      )
    end
  end

  def matching_team_member(square_name, by_name, by_first_name)
    normalized = normalize_staff_name(square_name)
    by_name[normalized] || first_name_match(square_name, by_first_name)
  end

  def first_name_match(square_name, by_first_name)
    matches = Array(by_first_name[first_staff_name(square_name)])
    matches.one? ? matches.first : nil
  end

  def normalize_staff_name(name)
    name.to_s.downcase.gsub(/[^a-z0-9\s]/, " ").squish
  end

  def first_staff_name(name)
    normalize_staff_name(name).split.first
  end

  def cached_bookable_staff
    Rails.cache.fetch(availability_staff_cache_key, expires_in: 5.minutes) do
      SquareApi.bookable_staff
    end
  rescue SquareApi::Error
    []
  end

  # Square team-member ids that take online bookings (booking-profile bookable).
  def bookable_staff_ids
    @bookable_staff_ids ||= cached_bookable_staff.map { |member| member[:id].to_s }.to_set
  end

  # Keep only slots served by a bookable technician. Slots for staff merely
  # assigned to the service (not bookable online) are dropped. `staff` is passed
  # in where already loaded to avoid a second lookup.
  def slots_for_staff(slots, staff = nil)
    ids = staff ? staff.map { |m| m[:id].to_s }.to_set : bookable_staff_ids
    Array(slots).select { |slot| ids.include?(slot[:team_member_id].to_s) }
  end

  def only_bookable_slots(slots)
    slots_for_staff(slots)
  end

  # True if the tech takes online bookings. When the bookable set is unknown
  # (Square staff lookup failed → empty), don't block booking — Square is the
  # backstop — so this returns true rather than rejecting everyone.
  def team_member_bookable?(team_member_id)
    ids = bookable_staff_ids
    ids.empty? || ids.include?(team_member_id.to_s)
  end

  def earliest_slot(slots)
    Array(slots).min_by { |slot| Time.iso8601(slot[:start_at].to_s) }
  rescue ArgumentError
    nil
  end

  def serialize_availability_slot(slot)
    return nil unless slot

    {
      start_at: slot[:start_at],
      team_member_id: slot[:team_member_id],
      service_variation_version: slot[:service_variation_version]
    }
  end

  def availability_options_cache_key
    "square:availability:options:#{SquareApi.environment}:#{SquareApi.location_id}"
  end

  def availability_staff_cache_key
    "square:availability:staff:#{SquareApi.environment}:#{SquareApi.location_id}"
  end

  def next_availability_cache_key(service_id:, date:, days:)
    "square:availability:next:#{SquareApi.environment}:#{SquareApi.location_id}:#{service_id}:#{date}:#{days}"
  end

  def render_square_unavailable
    render json: { error: "Online availability is unavailable right now." }, status: :service_unavailable
  end

  def render_invalid_availability_date
    render json: { error: "Choose today or a future date." }, status: :unprocessable_entity
  end

  def throttle_create
    throttle(
      scope: "book:create",
      limit: 10,
      period: 1.hour,
      message: "You've made several booking attempts. Please wait a bit and try again, or call us to book."
    )
  end

  # Silently reject automated submissions caught by the honeypot. We return a
  # generic 422 (never naming the trap) rather than a fake success, so that in
  # the rare event a real submission trips it — e.g. aggressive autofill — the
  # customer sees a clear "call us" path instead of thinking they booked.
  def reject_honeypot
    return if params[HONEYPOT_FIELD].blank?

    Rails.logger.warn("[Booking] honeypot triggered from #{request.remote_ip}")
    render json: {
      ok: false,
      error: "We couldn't complete that booking online. Please call us at #{support_phone} to book."
    }, status: :unprocessable_entity
  end

  def support_phone
    helpers.salon.phone_display
  rescue StandardError
    "the salon"
  end

  # Record a funnel event via Ahoy. Properties only — never customer PII (name,
  # phone, email values). Analytics must never break a booking.
  def track_event(name, **properties)
    ahoy.track(name, properties)
  rescue StandardError => e
    Rails.logger.warn("[Analytics] #{name} tracking failed: #{e.class}: #{e.message}")
  end
end
