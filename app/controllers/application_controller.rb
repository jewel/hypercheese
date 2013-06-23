class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!
  before_filter :verify_approval!

  def verify_approval!
    return if current_user.approved?
    redirect_to "/users/pending"
  end
end
