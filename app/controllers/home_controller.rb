class HomeController < ApplicationController
  def index
    render layout: "gallery"
  end

  def activity
    cache_path = Rails.root.join 'tmp/activities'
    json = {}
    if File.exists? cache_path
      json = JSON.parse File.binread(cache_path)
    end

    taggings = ActiveRecord::Base.connection.select_all("
      SELECT added_by, tag_id, DATE(created_at) date, MAX(created_at) created_at, SUM(1) count
      FROM item_tags
      WHERE created_at > DATE_SUB(NOW(), INTERVAL 45 DAY)
      GROUP BY 1, 2, 3
      ORDER BY created_at DESC
    ")

    taggings_by_group = {}
    taggings.each do |tagging|
      taggings_by_group[ "#{tagging["date"]}-#{tagging["added_by"]}" ] ||= []
      taggings_by_group[ "#{tagging["date"]}-#{tagging["added_by"]}" ].push tagging
    end

    user_ids = []

    json['activity'] += taggings_by_group.values.map do |list|
      user_ids.push list.first["added_by"]

      {
        "tagging" => {
          "user_id" => list.first["added_by"],
          "created_at" => list.first["created_at"],
          "list" => list.sort_by { |_| _["count"] }.reverse,
        },
      }
    end

    user_ids.uniq!
    users = User.find user_ids
    json['users'] += users.map { |_| UserSerializer.new(_).as_json }

    json['activity'] = json['activity'].sort_by do |_|
      _.values.first["created_at"]
    end.reverse

    json['new_items'] = current_user.items.where( published: nil ).count

    json['private_items'] = current_user.items.where( published: false ).count

    render json: json
  end
end
