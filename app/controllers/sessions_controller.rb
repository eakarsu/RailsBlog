class SessionsController < ApplicationController
  skip_forgery_protection only: :create, if: -> { request.format.json? }

  def new
    return unless params[:demo] == "1" && ENV["LOCAL_DEMO_AUTH"] == "true"

    @demo_email = ENV["BOOTSTRAP_ADMIN_EMAIL"].presence || ENV["PROVISION_ADMIN_EMAIL"].presence || ENV["ADMIN_EMAIL"].presence
    @demo_password = ENV["BOOTSTRAP_ADMIN_PASSWORD"].presence || ENV["PROVISION_ADMIN_PASSWORD"].presence || ENV["ADMIN_PASSWORD"].presence
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user&.active? && user.authenticate(params[:password].to_s)
      reset_session
      session[:user_id] = user.id
      user.update_column(:last_login_at, Time.current)
      respond_to do |format|
        format.html { redirect_to posts_path(mine: 1), notice: "Signed in." }
        format.json { render json: { user: session_user(user) } }
      end
    else
      sleep(0.05) unless Rails.env.test?
      respond_to do |format|
        format.html do
          flash.now[:alert] = "Invalid email or password."
          render :new, status: :unprocessable_entity
        end
        format.json { render json: { error: "invalid_email_or_password" }, status: :unauthorized }
      end
    end
  end

  def show
    user = current_user
    return render json: { error: "authentication_required" }, status: :unauthorized unless user

    render json: { user: session_user(user) }
  end

  def demo_credentials
    return head :not_found unless ENV["LOCAL_DEMO_AUTH"] == "true"
    email = ENV["BOOTSTRAP_ADMIN_EMAIL"].presence || ENV["PROVISION_ADMIN_EMAIL"].presence || ENV["ADMIN_EMAIL"].presence
    password = ENV["BOOTSTRAP_ADMIN_PASSWORD"].presence || ENV["PROVISION_ADMIN_PASSWORD"].presence || ENV["ADMIN_PASSWORD"].presence
    return render json: { error: "demo_credentials_unavailable" }, status: :service_unavailable if email.blank? || password.blank?
    response.headers["Cache-Control"] = "no-store"
    render json: { email: email, password: password }
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  private

  def session_user(user)
    { id: user.id, email: user.email, displayName: user.display_name, role: user.role }
  end
end
