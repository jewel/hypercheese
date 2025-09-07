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

    # Face detection events grouped by cluster tag
    face_detections = ActiveRecord::Base.connection.select_all("
      SELECT
        cluster_faces.tag_id,
        DATE(i.created_at) date,
        MAX(i.created_at) created_at,
        COUNT(f.id) face_count,
        GROUP_CONCAT(DISTINCT i.id) items,
        t.label as tag_label
      FROM faces f
      JOIN items i ON f.item_id = i.id
      LEFT JOIN faces cluster_faces ON f.cluster_id = cluster_faces.id
      LEFT JOIN tags t ON cluster_faces.tag_id = t.id
      WHERE i.created_at > DATE_SUB(NOW(), INTERVAL #{cutoff_days} DAY)
        AND i.deleted = 0
        AND i.published = 1
        AND f.cluster_id IS NOT NULL
        AND cluster_faces.tag_id IS NOT NULL
      GROUP BY 1, 2
      HAVING face_count > 0
      ORDER BY created_at DESC
    ")

    # Unidentified face events (faces without tags)
    unidentified_faces = ActiveRecord::Base.connection.select_all("
      SELECT
        DATE(i.created_at) date,
        MAX(i.created_at) created_at,
        GROUP_CONCAT(CONCAT(f.id, ':', i.id, ':', i.code) ORDER BY f.id) face_data,
        GROUP_CONCAT(DISTINCT i.id) items,
        COUNT(f.id) face_count
      FROM faces f
      JOIN items i ON f.item_id = i.id
      LEFT JOIN faces cluster_faces ON f.cluster_id = cluster_faces.id
      WHERE i.created_at > DATE_SUB(NOW(), INTERVAL #{cutoff_days} DAY)
        AND i.deleted = 0
        AND i.published = 1
        AND (f.cluster_id IS NULL OR cluster_faces.tag_id IS NULL)
        AND f.tag_id IS NULL
      GROUP BY DATE(i.created_at)
      HAVING face_count > 0
      ORDER BY created_at DESC
    ")

    face_detections.each do |detection|
      detection["items"] = CollapseRange.collapse detection["items"].split(",").map(&:to_i).sort
    end

    unidentified_faces.each do |detection|
      detection["items"] = CollapseRange.collapse detection["items"].split(",").map(&:to_i).sort
    end

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

    json['activity'] += unidentified_faces.map do |detection|
      faces = detection["face_data"].split(",").map do |face_info|
        face_id, item_id, item_code = face_info.split(":")
        {
          "face_id" => face_id.to_i,
          "item_id" => item_id.to_i,
          "item_code" => item_code,
        }
      end

      {
        "unidentified_faces" => {
          "created_at" => detection["created_at"],
          "face_count" => detection["face_count"].to_i,
          "items" => detection["items"],
          "faces" => faces,
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
