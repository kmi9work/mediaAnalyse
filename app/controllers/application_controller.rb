class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :require_login

  def disable_tracking
    session[:track_on] = false
  end
  def enable_tracking
    session[:track_on] = true
  end
  private
  def not_authenticated
    redirect_to login_url, :alert => "First log in to view this page."
  end
end
