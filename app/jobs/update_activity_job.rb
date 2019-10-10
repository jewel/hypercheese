require_dependency 'user_serializer'

class UpdateActivityJob < ActiveJob::Base
  queue_as :default

  class Group
    attr_accessor :photo_count
    attr_accessor :video_count
    attr_accessor :item
    attr_accessor :ids
    def created_at
      @item.created_at
    end
  end

  # Searches with lots of IDs are too long for GET URIs.  Collapse ranges,
  # since imported items will usually be in order.
  def collapse_range nums
    groups = []
    cur_seq = []
    groups << cur_seq
    nums.each do |num|
      if cur_seq.last && cur_seq.last + 1 == num
        cur_seq << num
      elsif cur_seq.empty?
        cur_seq << num
      else
        cur_seq = [num]
        groups << cur_seq
      end
    end

    groups.map! do |seq|
      if seq.size == 1
        "#{seq.first}"
      elsif seq.size == 2
        "#{seq.first},#{seq.last}"
      else
        "#{seq.first}-#{seq.last}"
      end
    end

    groups.join ","
  end

  def perform(*args)
    cutoff = 45.days.ago
    events = []
    # events += Comment.includes(:item, :user).where('created_at > ?', cutoff).to_a
    events += Bullhorn.includes(:item, :user).where('created_at > ?', cutoff).to_a

    recent = Item.includes(:item_paths).where('deleted = 0').where('created_at > ?', cutoff)
    delete_tag = Tag.where( label: 'delete' ).first
    if delete_tag
      recent = recent.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', delete_tag.id ]
    end
    hidden_tag = Tag.where( label: 'Hidden' ).first
    if hidden_tag
      recent = recent.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', hidden_tag.id ]
    end

    recent = recent.sort_by do |item|
      [item.directory, item.created_at]
    end

    groups = []
    last = Group.new
    recent.each do |item|
      if !last.item || last.item.directory != item.directory || item.created_at - last.item.created_at > 8.hours
        groups << last if last.item
        last = Group.new
      end
      last.item ||= item
      if item.variety == 'video'
        last.video_count ||= 0
        last.video_count += 1
      else
        last.photo_count ||= 0
        last.photo_count += 1
      end
      last.ids ||= []
      last.ids << item.id
    end
    groups << last if last.item

    groups.each do |group|
      group.ids = collapse_range group.ids.sort
    end

    events += groups
    events = events.sort_by(&:created_at).reverse

    sources = Source.where show_on_home: true
    sources = ActiveModel::Serializer::CollectionSerializer.new sources, each_serializer: SourceSerializer

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

        label = event.item.source.try(:label) || 'Unknown'

        {
          item_group: {
            created_at: event.created_at,
            photo_count: event.photo_count,
            video_count: event.video_count,
            source: label,
            ids: event.ids,
            item_id: event.item.id,
          }
        }
      when Comment
        comment = CommentSerializer.new(event).as_json
        comment.delete "users"
        json[:users].push event.user
        json[:items].push event.item
        comment
      when Bullhorn
        bullhorn = BullhornSerializer.new(event).as_json
        bullhorn.delete "users"
        json[:users].push event.user
        json[:items].push event.item
        {
          bullhorn: bullhorn
        }
      end
    end
    json[:users].uniq!
    json[:items].uniq!

    json[:users].map! { |_| UserSerializer.new(_).as_json }
    json[:items].map! { |_| ItemSerializer.new(_).as_json }

    cache_path = Rails.root.join "tmp/activities"
    tmp = "#{cache_path}.#$$.tmp"

    File.binwrite tmp, json.to_json
    File.rename tmp, cache_path
  end
end
