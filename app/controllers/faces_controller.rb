class FacesController < ApplicationController
  def index
    @tags = Tag.find_by_sql "
      WITH clusters AS (
        SELECT cluster_id, SUM(1) count FROM faces
        WHERE cluster_id IS NOT NULL
        GROUP BY 1
      ),
      total_faces AS (
        SELECT tag_id, SUM(count) count FROM faces
        JOIN clusters ON faces.id = clusters.cluster_id
        GROUP BY 1
      ),
      total_items AS (
        SELECT tag_id, SUM(1) count FROM item_tags
        JOIN items ON item_id = items.id
        WHERE face_count IS NOT NULL
        GROUP BY 1
      )
      SELECT tags.*, total_faces.count total_faces, total_items.count total_items
      FROM tags
      LEFT JOIN total_faces ON tag_id = tags.id
      LEFT JOIN total_items ON total_items.tag_id = tags.id
      HAVING total_faces > 0
      ORDER by total_faces DESC
    "
  end

  def uncanonize
    Face.transaction do
      @face = Face.find params[:id]
      @face.tag = nil
      @face.cluster_id = nil
      @face.similarity = nil
      @face.confirmed_by = nil
      @face.confirmed_at = nil
      @face.join_cluster
      @face.save!
      @face.destroy_cluster
    end
    redirect_to "/faces/#{@face.id}", notice: "No longer canon"
  end

  def canonize
    Face.transaction do
      @face = Face.find params[:id]
      @tag = Tag.find_by_label params[:label]
      redirect_to "/faces/#{@face.id}", alert: "No such tag: #{params[:label].inspect}" unless @tag

      @face.tag = @tag
      @face.confirmed_by = current_user.id
      @face.confirmed_at = Time.now
      @face.cluster_id = @face.id
      @face.similarity = 1

      @face.save!
      @face.build_cluster
    end
    redirect_to "/faces/#{@face.id}", notice: "Canonized as #{@tag.label}"
  end

  def show
    @face = Face.find params[:id]
    @canonical_faces = Face.where.not(tag: nil).sort_by do |canon|
      canon.embedding? && @face.embedding? && canon.distance(@face)
    end.reverse.first(10)

    if @face.tag
      @other_canonical = Face.where(tag_id: @face.tag.id).to_a - [@face]
      @cluster = Face.where(cluster_id: @face.id).includes(:item).order('similarity desc').limit(10_000)
      @birthday = @face.tag.birthday
      @birthday ||= @face.tag.items.order('taken').first&.taken
    else
      @hypothetical = {}
      output = @face.store.bulk_cosine_distance @face.embedding, Face::DISTANCE_THRESHOLD
      ids = output.map &:last
      faces_by_id = Face.includes(:item, :cluster, cluster: :tag).where(id: ids).where(tag_id: nil).index_by &:id
      output.each do |(distance, id)|
        other = faces_by_id[id]
        next unless other # face must have been deleted
        next if other.cluster_id && other.similarity >= distance
        @hypothetical[other.cluster&.tag] ||= []
        @hypothetical[other.cluster&.tag] << other
      end
    end
  end

  def unclustered
    ids = []
    max = Face.maximum(:id)
    2048.times do
      ids << rand(max)
    end
    @faces = Face.where(cluster_id: nil, id: ids)
  end

  def mistagged
    @tag = Tag.find_by_id params[:tag_id]

    # Images that are tagged with a person but do not have his face in them
    @items = Item.find_by_sql ["
      SELECT items.*
      FROM item_tags
      JOIN items ON item_id = items.id
      WHERE tag_id = ?
      AND face_count IS NOT NULL
      AND item_id NOT IN (
        SELECT item_id
        FROM faces
        WHERE cluster_id IN (
          SELECT id
          FROM faces
          WHERE tag_id = ?
        )
      )
      ORDER BY taken DESC
      LIMIT 1000
    ", @tag.id, @tag.id]
  end

  def untagged
    @tag = Tag.find_by_id params[:tag_id]

    # Faces that are in an image that doesn't have that tag
    @faces = Face.find_by_sql ["
      SELECT faces.* FROM faces
      WHERE cluster_id IN (
        SELECT id
        FROM faces
        WHERE tag_id = ?
      )
      AND item_id NOT IN (
        SELECT item_id
        FROM item_tags
        WHERE tag_id = ?
      )
      ORDER BY similarity DESC
      LIMIT 1000
    ", @tag.id, @tag.id]
  end


  # TODO:
      # Images that are not tagged Ezra, but is tagged, but do have his face in them
      # Images that are not tagged at all that have his face in them
end
