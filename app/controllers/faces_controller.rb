class FacesController < ApplicationController
  def show
    @face = Face.find params[:id]
    @canonical_faces = Face.where.not(tag: nil).sort_by do |canon|
      canon.embedding? && @face.embedding? && canon.distance(@face)
    end.reverse
    if @face.tag
      @other_canonical = Face.where(tag: @face.cluster.tag)
      @cluster = Face.where(cluster: @face.cluster).order('similarity desc').limit(10000)
    end
  end
end
