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
      SELECT id, code, created_at
      FROM items
      WHERE created_at > DATE_SUB(NOW(), INTERVAL #{cutoff_days} DAY)
        AND deleted = 0
        AND published = 1
      ORDER BY created_at DESC
    ")

    # Get identified faces for those items
    if recent_items.any?
      item_ids = recent_items.map { |item| item["id"] }.join(",")
      identified_face_data = ActiveRecord::Base.connection.select_all("
        SELECT f.id, f.item_id, i.code, i.created_at, cluster_faces.tag_id, t.label as tag_label
        FROM faces f
        JOIN items i ON f.item_id = i.id
        LEFT JOIN faces cluster_faces ON f.cluster_id = cluster_faces.id
        LEFT JOIN tags t ON cluster_faces.tag_id = t.id
        WHERE f.item_id IN (#{item_ids})
          AND f.cluster_id IS NOT NULL
          AND cluster_faces.tag_id IS NOT NULL
        ORDER BY f.id
      ")
    else
      identified_face_data = []
    end

    # Get unidentified faces for those items
    if recent_items.any?
      item_ids = recent_items.map { |item| item["id"] }.join(",")
      unidentified_face_data = ActiveRecord::Base.connection.select_all("
        SELECT f.id, f.item_id, i.code, i.created_at
        FROM faces f
        JOIN items i ON f.item_id = i.id
        WHERE f.item_id IN (#{item_ids})
          AND f.tag_id IS NULL
          AND f.cluster_id IS NULL
          AND i.variety = 'photo'
        ORDER BY f.id
      ")
    else
      unidentified_face_data = []
    end

    # Group identified faces by tag and date in Ruby
    identified_faces_by_tag_and_date = {}
    identified_face_data.each do |face|
      tag_id = face["tag_id"].to_i
      date = face["created_at"].to_date
      key = "#{tag_id}-#{date}"

      identified_faces_by_tag_and_date[key] ||= {
        "tag_id" => tag_id,
        "tag_label" => face["tag_label"],
        "date" => date,
        "created_at" => face["created_at"],
        "faces" => [],
        "items" => []
      }

      identified_faces_by_tag_and_date[key]["faces"] << face["id"].to_i
      identified_faces_by_tag_and_date[key]["items"] << face["item_id"].to_i
      # Update to latest created_at for this group
      if face["created_at"] > identified_faces_by_tag_and_date[key]["created_at"]
        identified_faces_by_tag_and_date[key]["created_at"] = face["created_at"]
      end
    end

    # Convert to final structure
    face_detections = identified_faces_by_tag_and_date.values.map do |group|
      {
        "tag_id" => group["tag_id"],
        "tag_label" => group["tag_label"],
        "date" => group["date"].to_s,
        "created_at" => group["created_at"],
        "face_count" => group["faces"].size,
        "items" => CollapseRange.collapse(group["items"].uniq.sort)
      }
    end

    # Group unidentified faces by date in Ruby
    unidentified_faces_by_date = {}
    unidentified_face_data.each do |face|
      date = face["created_at"].to_date
      unidentified_faces_by_date[date] ||= {
        "date" => date,
        "created_at" => face["created_at"],
        "faces" => []
      }
      unidentified_faces_by_date[date]["faces"] << {
        "face_id" => face["id"].to_i,
        "item_id" => face["item_id"].to_i,
        "item_code" => face["code"]
      }
    end

    # Convert to array and update created_at to max for each day
    unidentified_faces = unidentified_faces_by_date.values.map do |day_data|
      max_created_at = day_data["faces"].map { |f| f["created_at"] || day_data["created_at"] }.max || day_data["created_at"]
      day_data["created_at"] = max_created_at
      day_data["face_count"] = day_data["faces"].size
      # Create items list for compatibility
      day_data["items"] = CollapseRange.collapse(day_data["faces"].map { |f| f["item_id"] }.uniq.sort)
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
