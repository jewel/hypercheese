class FacesController < ApplicationController
  def show
    # FIXME Add authorization check?
    @face = Face.find params[:id]
    @canonical_faces = Face.where.not(tag: nil).sort_by do |canon|
      canon.embedding? && @face.embedding? && canon.distance(@face)
    end.reverse
    if @face.tag
      @other_canonical = Face.where(tag: @face.cluster.tag)
      @cluster = Face.where(cluster: @face.cluster).order('similarity desc').limit(1000)
    end
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
