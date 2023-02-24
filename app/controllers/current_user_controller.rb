class CurrentUserController < ApplicationController
  def current
    render json: { can_write: current_user&.can_write? }
  end
end
