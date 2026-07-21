class SessionsController < ApplicationController
  def new; end

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

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  private

  def session_user(user)
    { id: user.id, email: user.email, displayName: user.display_name, role: user.role }
  end
end
