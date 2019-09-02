class User::PasswordsController < Devise::PasswordsController
  skip_before_action :verify_approval!
end
