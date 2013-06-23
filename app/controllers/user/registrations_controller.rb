class User::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :verify_approval!

  def pending
    if current_user.approved?
      redirect_to "/"
    end
  end
end
