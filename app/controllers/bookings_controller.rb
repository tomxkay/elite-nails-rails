# Native on-site booking flow backed by the Square Bookings API (Phase D2).
# GET /book renders the wizard; availability + create are called by the
# `booking` Stimulus controller as JSON.
class BookingsController < ApplicationController
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
      note: params[:note].presence
    )
    render json: { ok: true, booking: { id: booking["id"], start_at: booking["start_at"], status: booking["status"] } }
  rescue ActionController::ParameterMissing => e
    render json: { ok: false, error: "Missing required field: #{e.param}" }, status: :unprocessable_entity
  rescue SquareApi::Error => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end
end
