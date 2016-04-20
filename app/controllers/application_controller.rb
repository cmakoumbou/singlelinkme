class ApplicationController < ActionController::Base
	before_action :configure_permitted_parameters, if: :devise_controller?

  protect_from_forgery with: :exception

  def after_sign_in_path_for(resource)
    @user = current_user
    if @user.subscriptions.empty?
      '/subscriptions'
    else
      root_path
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to main_app.subscriptions_path, :alert => exception.message
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:display_name, :bio, :avatar, :remove_avatar, :name_colour,
     :bio_colour, :singlelink_colour, :topbg_colour, :botbg_colour) }
  end
end