module ApplicationHelper
  def event_url event
    "/e/#{event.id}/#{event.name}"
  end
end
