class User::SessionsController < Devise::SessionsController
  skip_before_action :verify_approval!
end
