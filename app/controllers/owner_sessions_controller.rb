class OwnerSessionsController < ApplicationController
  layout false

  # Login page shown when Doorkeeper needs the owner authenticated (OAuth flow).
  def new
    @return_to = params[:return_to]
  end

  def create
    expected = ENV["MCP_OWNER_PASSWORD"].to_s
    given = params[:password].to_s

    if expected.present? && ActiveSupport::SecurityUtils.secure_compare(given, expected)
      session[:mcp_owner] = true
      redirect_to(safe_return_to(params[:return_to]))
    else
      @return_to = params[:return_to]
      flash.now[:alert] = "Incorrect password."
      render :new, status: :unauthorized
    end
  end

  def destroy
    reset_session
    redirect_to("/owner/login")
  end

  private

  # Only ever redirect to a local path (avoid open-redirect via return_to).
  def safe_return_to(path)
    path.to_s.start_with?("/") && !path.to_s.start_with?("//") ? path : "/"
  end
end
