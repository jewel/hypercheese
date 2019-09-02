class User::RegistrationsController < Devise::RegistrationsController
  skip_before_action :verify_approval!

  def pending
    if !current_user
      redirect_to "/"
    elsif current_user.approved?
      redirect_to "/"
    end
  end
end
