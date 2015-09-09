class CustomFailure < Devise::FailureApp
  def redirect_url
    users_choose_url
  end
end
