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
  before_action :throttle_availability, only: :availability
  before_action :throttle_create,       only: :create
  before_action :reject_honeypot,       only: :create

  # GET /book
  def show
    unless SquareApi.configured?
      redirect_to(ENV["BOOKING_URL"].presence || root_path, allow_other_host: true)
      return
    end

    @services = SquareApi.services
    # Staff list is optional ("Anyone available" works without it) — e.g. it
    # 401s until the Square account finishes Appointments onboarding.
    @staff = begin
      SquareApi.bookable_staff
    rescue SquareApi::Error
      []
    end
  rescue SquareApi::Error => e
    @error = e.message
    @services = []
    @staff = []
  end

  # GET /book/availability?service_id=&service_version=&date=YYYY-MM-DD&team_member_id=
  def availability
    date = begin
      Date.iso8601(params[:date].to_s)
    rescue Date::Error
      Date.current
    end
    window_start = [ date.in_time_zone.beginning_of_day, Time.current + 30.minutes ].max
    window_end = date.in_time_zone.end_of_day

    slots = SquareApi.availability(
      service_variation_id: params.require(:service_id),
      start_at: window_start.utc,
      end_at: window_end.utc,
      team_member_id: params[:team_member_id].presence
    )
    render json: { slots: slots }
  rescue ActionController::ParameterMissing
    render json: { error: "Pick a service first" }, status: :unprocessable_entity
  rescue SquareApi::Error => e
    render json: { error: e.message }, status: :bad_gateway
  end

  # POST /book
  def create
    idempotency_key = params.require(:idempotency_key)
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
      team_member_id: params.require(:team_member_id),
      idempotency_key: idempotency_key,
      note: params[:note].presence
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
end
