class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :current_user, :signed_in?

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::StaleObjectError, with: :conflict
  rescue_from Publishing::PostWorkflow::Forbidden, Publishing::PostEditor::Forbidden,
              Publishing::CommentModerator::Forbidden, with: :forbidden

  private

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = User.find_by(id: session[:user_id], status: "active")
  end

  def signed_in?
    current_user.present?
  end

  def authenticate!
    return if signed_in?
    respond_to do |format|
      format.html { redirect_to login_path, alert: "Please sign in." }
      format.any { render json: { error: "authentication_required" }, status: :unauthorized }
    end
  end

  def require_editor!
    forbidden unless current_user&.editor?
  end

  def require_moderator!
    forbidden unless current_user&.moderator?
  end

  def forbidden(_exception = nil)
    respond_to do |format|
      format.html { render plain: "Forbidden", status: :forbidden }
      format.any { render json: { error: "forbidden" }, status: :forbidden }
    end
  end

  def not_found
    render plain: "Not found", status: :not_found
  end

  def conflict
    render json: { error: "edit_conflict", message: "The article changed; reload before retrying." }, status: :conflict
  end
end
