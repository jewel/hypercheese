class CurrentUserController < ApplicationController
  def current
    render json: {
      can_write: current_user&.can_write?,
      is_admin: current_user&.is_admin?,
    }
  end
end
