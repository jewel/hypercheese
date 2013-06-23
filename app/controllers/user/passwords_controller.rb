class User::PasswordsController < Devise::PasswordsController
  skip_before_filter :verify_approval!
end
