# Mints a buyer-scoped Square OAuth token for the native booking flow.
# Square classifies Bookings API writes by the token's scopes: a token holding
# ONLY buyer-level scopes can create customer self-bookings on the FREE
# Appointments plan, while all-scope tokens (personal access tokens) are
# treated as seller-level and 403 without a paid plan.
#
# Flow (run by the developer, once per seller + on ~30-day expiry until
# automated refresh lands): GET /square/authorize → Square consent → callback
# exchanges the code and displays the tokens to paste into env/secrets.
class SquareOauthController < ApplicationController
  # Buyer-level writes + the reads the /book wizard needs. Deliberately NOT
  # APPOINTMENTS_ALL_WRITE — that would make the token seller-level.
  SCOPES = %w[
    APPOINTMENTS_READ
    APPOINTMENTS_WRITE
    APPOINTMENTS_ALL_READ
    APPOINTMENTS_BUSINESS_SETTINGS_READ
    CUSTOMERS_READ
    CUSTOMERS_WRITE
    ITEMS_READ
  ].freeze

  before_action :require_app_credentials

  def authorize
    state = SecureRandom.hex(16)
    session[:square_oauth_state] = state
    redirect_to "#{oauth_base}/oauth2/authorize?" + {
      client_id: ENV["SQUARE_APP_ID"],
      scope: SCOPES.join(" "),
      state: state
    }.to_query, allow_other_host: true
  end

  def callback
    if params[:error].present?
      return render plain: "Square authorization failed: #{params[:error]} (#{params[:error_description]})", status: :bad_gateway
    end
    unless params[:state].present? && params[:state] == session.delete(:square_oauth_state)
      return render plain: "State mismatch — start again at /square/authorize", status: :unprocessable_entity
    end

    payload = SquareApi.oauth_token(
      grant_type: "authorization_code",
      code: params.require(:code),
      redirect_uri: square_callback_url
    )
    # Persist so SquareApi uses (and lazily refreshes) it from the DB — no
    # env-var paste needed after this.
    SquareCredential.store_oauth!(payload, environment: SquareApi.environment)
    render :callback, locals: { token: payload }
  rescue SquareApi::Error => e
    render plain: "Token exchange failed: #{e.message}", status: :bad_gateway
  end

  private

  def require_app_credentials
    return if ENV["SQUARE_APP_ID"].present? && ENV["SQUARE_APP_SECRET"].present?

    render plain: "SQUARE_APP_ID / SQUARE_APP_SECRET are not configured", status: :not_found
  end

  def oauth_base
    SquareApi.base_url
  end
end
