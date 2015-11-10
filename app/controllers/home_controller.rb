class HomeController < ApplicationController
  def index
    render layout: "gallery"
  end

  def activity
    # TODO Take all photos uploaded in the last month, sort into batches (where
    # a batch is a group of photos all uploaded from the same source where
    # there is no more than twenty minutes between each photo's upload date.
    events = []
    events += Item.order('created_at desc').limit(5).to_a
    # TODO Add Tag change history
    events += Comment.order('created_at desc').includes(:item, :user).limit(5).to_a
    events = events.sort_by(&:created_at).reverse

    json = {
      activity: events,
      users: [],
      items: [],
    }
    json[:activity].map! do |event|
      case event
      when Item
        ItemSerializer.new(event).as_json
      when Comment
        comment = CommentSerializer.new(event).as_json
        comment.delete :users
        json[:users].push event.user
        json[:items].push event.item
        comment
      end
    end
    json[:users].map { |_| UserSerializer.new(_).as_json[:user] }
    json[:users].uniq!
    json[:items].map { |_| ItemSerializer.new(_).as_json[:item] }

    render json: json
  end
end
