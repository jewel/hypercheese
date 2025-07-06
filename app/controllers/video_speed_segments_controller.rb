class VideoSpeedSegmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item
  before_action :set_segment, only: [:show, :update, :destroy]

  # GET /items/:item_id/video_speed_segments
  def index
    @segments = @item.video_speed_segments.ordered
    render json: @segments
  end

  # GET /items/:item_id/video_speed_segments/:id
  def show
    render json: @segment
  end

  # POST /items/:item_id/video_speed_segments
  def create
    @segment = @item.video_speed_segments.build(segment_params)
    @segment.source_type = 'manual'

    if @segment.save
      render json: @segment, status: :created
    else
      render json: { errors: @segment.errors }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /items/:item_id/video_speed_segments/:id
  def update
    if @segment.update(segment_params)
      render json: @segment
    else
      render json: { errors: @segment.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /items/:item_id/video_speed_segments/:id
  def destroy
    @segment.destroy
    head :no_content
  end

  # POST /items/:item_id/video_speed_segments/extract
  def extract
    unless @item.video?
      return render json: { error: 'Item is not a video' }, status: :unprocessable_entity
    end

    begin
      extractor = VideoMetadataExtractor.new(@item)
      segments_created = extractor.extract_and_create_speed_segments!
      
      if segments_created
        @segments = @item.video_speed_segments.ordered
        render json: { 
          message: "Extracted #{@segments.count} speed segments",
          segments: @segments
        }
      else
        render json: { message: 'No speed segments found in metadata' }
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  private

  def set_item
    @item = Item.find(params[:item_id])
  end

  def set_segment
    @segment = @item.video_speed_segments.find(params[:id])
  end

  def segment_params
    params.require(:video_speed_segment).permit(:start_time, :end_time, :playback_rate, :metadata)
  end
end