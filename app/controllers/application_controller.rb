class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_filter :authenticate_user!
  before_filter :verify_approval!

  def verify_approval!
    raise "Attempting to verify before authenticated" unless current_user
    return if current_user.approved?
    redirect_to "/users/pending"
  end

  def handle_unverified_request
    raise "CSRF Failure"
  end

  protected

  include ActionController::Streaming
  include Zipline

  def download_zip items
    if items.size == 1
      return send_file items.first.full_path
    end

    # FIXME This won't work with more than 1024 files

    files = items.map do |item|
      path = File.realpath item.full_path
      [File.open(path, 'rb'), File.basename(item.full_path)]
    end

    zipline files, "#{files.size}-from-hypercheese.zip"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit :username, :email, :password, :password_confirmation, :remember_me
    end
    devise_parameter_sanitizer.for(:sign_in) do |u|
      u.permit :login, :username, :email, :password, :remember_me
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit :username, :email, :password, :password_confirmation, :current_password
    end
  end
end
