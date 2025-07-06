class FaceTrailsController < ApplicationController
  respond_to :json

  def show
    @face_trail = FaceTrail.find params[:id]
    @face_trail.item.check_visibility_for current_user
    render json: @face_trail
  end

  def faces
    @face_trail = FaceTrail.find params[:id]
    @face_trail.item.check_visibility_for current_user
    
    # Get all faces with embeddings for this trail, ordered by timestamp
    faces = @face_trail.faces_with_embeddings.includes(:tag, :cluster).order(:timestamp)
    
    faces_data = faces.map do |face|
      {
        id: face.id,
        timestamp: face.timestamp,
        tag_id: face.tag_id,
        cluster_tag_id: face.cluster&.tag_id,
        similarity: face.similarity,
        tag_name: face.tag&.label || face.cluster&.tag&.label
      }
    end
    
    render json: { faces: faces_data }
  end
end