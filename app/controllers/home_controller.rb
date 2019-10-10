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
      SELECT tag_id, DATE(created_at) date, MAX(created_at) created_at, SUM(1) count
      FROM item_tags
      WHERE created_at > DATE_SUB(NOW(), INTERVAL 7 DAY)
      GROUP BY 1, 2
      ORDER BY count DESC
    ")

    taggings_by_day = {}
    taggings.each do |tagging|
      taggings_by_day[ tagging["date"] ] ||= []
      taggings_by_day[ tagging["date"] ].push tagging
    end

    json['activity'] += taggings_by_day.values.map do |list|
      {
        "tagging" => {
          "created_at" => list.first["created_at"],
          "list" => list,
        },
      }
    end

    json['activity'] = json['activity'].sort_by do |_|
      _.values.first["created_at"]
    end.reverse

    render json: json
  end
end
