class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :verify_approval!
  before_filter :authenticate_user!

  def verify_approval!
    return if current_user.role != 'stranger'
    redirect_to "/registrations/pending"
  end
end
