class PlacesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_place, only: [:show, :edit, :update, :destroy]

  # GET /places
  def index
    @places = Place.includes(:creator).order(:name)
    render json: @places, each_serializer: PlaceSerializer
  end

  # GET /places with item counts
  def with_item_counts
    places = Place.left_joins(item_places: :item)
                  .where('items.deleted = ? OR items.deleted IS NULL', false)
                  .where('items.published = ? OR items.published IS NULL', true)
                  .select('places.*, COUNT(item_places.item_id) as item_count')
                  .group('places.id')
                  .order('item_count DESC')

    render json: places.as_json(methods: [:item_count])
  end

  # GET /places/1
  def show
    render json: @place, serializer: PlaceSerializer
  end

  # POST /places
  def create
    require_write!
    @place = Place.new(place_params)
    @place.created_by = current_user.id

    if @place.save
      # Associate existing items with this place
      @place.associate_existing_items!
      render json: @place, serializer: PlaceSerializer, status: :created
    else
      render json: { errors: @place.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /places/1
  def update
    require_write!
    if @place.update(place_params)
      # Update item associations if coordinates or radius changed
      @place.update_item_associations!
      render json: @place, serializer: PlaceSerializer
    else
      render json: { errors: @place.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /places/1
  def destroy
    require_write!
    @place.destroy
    head :no_content
  end

  private

  def set_place
    @place = Place.find(params[:id])
  end

  def place_params
    params.require(:place).permit(:name, :latitude, :longitude, :radius)
  end
end
