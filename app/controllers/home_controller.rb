class HomeController < ApplicationController
  class Group
    attr :count, true
    attr :item, true
    def created_at
      @item.created_at
    end
  end

  def index
    render layout: "gallery"
  end

  def activity
    # TODO Add Tag change history

    cutoff = 90.days.ago
    events = []
    events += Comment.includes(:item, :user).where('created_at > ?', cutoff).to_a
    events += Star.includes(:item, :user).where('created_at > ?', cutoff).to_a

    recent = Item.where('created_at > ?', cutoff).order('created_at')

    groups = []
    last = Group.new
    recent.each do |item|
      if !last.item || item.taken - last.item.taken > 8.hours
        groups << last if last.item
        last = Group.new
      end
      last.item ||= item
      last.count ||= 0
      last.count += 1
    end
    groups << last if last.item
    events += groups
    events = events.sort_by(&:created_at).reverse

    sources = Source.where show_on_home: true
    sources = ActiveModel::ArraySerializer.new sources, each_serializer: SourceSerializer

    json = {
      activity: events,
      users: [],
      items: [],
      sources: sources
    }

    json[:activity].map! do |event|
      case event
      when Group
        json[:items].push event.item
        {
          item_group: {
            created_at: event.created_at,
            text: "#{event.count} items imported",
            item_id: event.item.id
          }
        }
      when Comment
        comment = CommentSerializer.new(event).as_json
        comment.delete "users"
        json[:users].push event.user
        json[:items].push event.item
        comment
      when Star
        star = StarSerializer.new(event).as_json
        star.delete "users"
        json[:users].push event.user
        json[:items].push event.item
        star
      end
    end
    json[:users].uniq!
    json[:items].uniq!

    render json: json
  end
end
