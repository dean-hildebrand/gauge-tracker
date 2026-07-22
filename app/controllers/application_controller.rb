class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Prevents double redirect when signing out
  def after_sign_out_path_for(_resource)
    new_user_session_path
  end

  private

  def require_employee!
    redirect_to root_path, alert: "Only employees can do that." unless current_user.employee?
  end

  def require_manager!
    redirect_to root_path, alert: "Only managers can do that." unless current_user.manager?
  end
end
