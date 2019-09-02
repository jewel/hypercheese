class User::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_approval!

  def facebook
    @user = User.find_for_facebook_oauth(request.env['omniauth.auth'], current_user)

    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: "Facebook")
  end
end
