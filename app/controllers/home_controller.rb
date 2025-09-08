require_dependency 'collapse_range'

class HomeController < ApplicationController
  def index
    render layout: "gallery"
  end

  def activity
    cache_path = Rails.root.join 'tmp/activities'
    json = {}
    if File.exist? cache_path
      json = JSON.parse File.binread(cache_path)
    end

    cutoff_days = Rails.env.development? ? 450 : 45
    taggings = ActiveRecord::Base.connection.select_all("
      SELECT added_by, tag_id, DATE(created_at) date, MAX(created_at) created_at, SUM(1) count, GROUP_CONCAT(item_id) items
      FROM item_tags
      WHERE created_at > DATE_SUB(NOW(), INTERVAL #{cutoff_days} DAY)
      GROUP BY 1, 2, 3
      ORDER BY created_at DESC
    ")

    taggings.each do |tagging|
      tagging["items"] = CollapseRange.collapse tagging["items"].split(",").map(&:to_i).sort
    end

    taggings_by_group = {}
    taggings.each do |tagging|
      taggings_by_group[ "#{tagging["date"]}-#{tagging["added_by"]}" ] ||= []
      taggings_by_group[ "#{tagging["date"]}-#{tagging["added_by"]}" ].push tagging
    end

    # Get recent items first
    recent_items = ActiveRecord::Base.connection.select_all("
      SELECT id, code, created_at, variety
      FROM items
      WHERE created_at > DATE_SUB(NOW(), INTERVAL #{cutoff_days} DAY)
        AND deleted = 0
        AND published = 1
      ORDER BY created_at DESC
    ")
    recent_items_by_id = recent_items.index_by { |item| item["id"] }

    recent_item_ids = recent_items.map { |item| item["id"] }.join(",")
    recent_item_ids = "NULL" if recent_item_ids.empty?

    # Get face clusters
    face_cluster_data = ActiveRecord::Base.connection.select_all("
      SELECT id, item_id, tag_id
      FROM faces
      WHERE tag_id IS NOT NULL
    ")
    tag_by_cluster_id = {}
    face_cluster_data.each do |row|
      tag_by_cluster_id[row["id"]] = row["tag_id"]
    end

    # Get all faces for recent items
    face_data = ActiveRecord::Base.connection.select_all("
      SELECT id, item_id, cluster_id
      FROM faces
      WHERE item_id IN (#{recent_item_ids})
    ")

    # Group identified faces by tag and date in Ruby
    identified_faces_by_tag_and_date = {}
    face_data.each do |face|
      tag_id = tag_by_cluster_id[face["cluster_id"]]
      next unless tag_id
      item = recent_items_by_id[face["item_id"]]
      date = item["created_at"].to_date
      key = "#{tag_id}-#{date}"

      entry = identified_faces_by_tag_and_date[key] ||= {
        "tag_id" => tag_id,
        "date" => date,
        "created_at" => item["created_at"],
        "faces" => [],
        "items" => []
      }

      entry["faces"] << face["id"].to_i
      entry["items"] << face["item_id"].to_i
      # Update to latest created_at for this group
      if item["created_at"] > entry["created_at"]
        entry["created_at"] = item["created_at"]
      end
    end

    # Convert to final structure
    face_detections = identified_faces_by_tag_and_date.values.map do |group|
      {
        "tag_id" => group["tag_id"],
        "date" => group["date"].to_s,
        "created_at" => group["created_at"],
        "face_count" => group["faces"].size,
        "items" => CollapseRange.collapse(group["items"].uniq.sort)
      }
    end

    # Group unidentified faces by date in Ruby
    unidentified_faces_by_date = {}
    face_data.each do |face|
      tag_id = tag_by_cluster_id[face["cluster_id"]]
      next if tag_id
      item = recent_items_by_id[face["item_id"]]
      next unless item["variety"] == "photo"

      date = item["created_at"].to_date
      key = "#{date}"
      unidentified_faces_by_date[date] ||= {
        "date" => date,
        "created_at" => item["created_at"],
        "faces" => []
      }
      unidentified_faces_by_date[date]["faces"] << {
        "face_id" => face["id"].to_i,
        "item_id" => face["item_id"].to_i,
        "item_code" => item["code"]
      }
    end

    # Convert to array and update created_at to max for each day
    unidentified_faces = unidentified_faces_by_date.values.map do |day_data|
      max_created_at = day_data["faces"].map { |f| f["created_at"] }.max || day_data["created_at"]
      day_data["created_at"] = max_created_at
      day_data["face_count"] = day_data["faces"].size
      day_data
    end.sort_by { |d| d["created_at"] }.reverse

    # Group face detections by date
    face_detections_by_date = {}
    face_detections.each do |detection|
      face_detections_by_date[detection["date"]] ||= []
      face_detections_by_date[detection["date"]].push detection
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

    json['activity'] += face_detections_by_date.values.map do |list|
      {
        "face_detection" => {
          "created_at" => list.first["created_at"],
          "list" => list.map do |detection|
            {
              "face_count" => detection["face_count"].to_i,
              "items" => detection["items"],
              "tag_id" => detection["tag_id"].to_i,
              "tag_label" => detection["tag_label"],
            }
          end.sort_by { |_| _["face_count"] }.reverse,
        },
      }
    end

    json['activity'] += unidentified_faces.map do |day_data|
      {
        "unidentified_faces" => {
          "created_at" => day_data["created_at"],
          "face_count" => day_data["face_count"],
          "items" => day_data["items"],
          "faces" => day_data["faces"],
        },
      }
    end

    user_ids.uniq!
    users = User.find user_ids
    json['users'] += users.map { |_| UserSerializer.new(_).as_json }

    json['activity'] = json['activity'].sort_by do |_|
      _.values.first["created_at"]
    end.reverse

    render json: json
  end

  def unpublished_item_counts
    json = {}
    json['new_items'] = current_user.items.where( published: nil ).from("items USE INDEX (index_items_on_published)").count
    json['private_items'] = current_user.items.where( published: false ).from("items USE INDEX (index_items_on_published)").count
    render json: json
  end
end
