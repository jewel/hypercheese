require_dependency 'tag_parser'
require_dependency 'search'
require 'tempfile'
require 'mimetype_fu'
require 'zip/zip'

class ItemsController < ApplicationController
  # GET /items/:id
  def show
    @start_time = Time.new
    @item = Item.find params[:id].to_i

    if @item.variety == 'photo'
      @view_count = @item.view_count ||= 0
      @item.view_count += 1
      @item.save
    end

    @query = params[:q] || ''

    item_ids = Rails.cache.fetch( "items-#@query" ) do
      Search.new( @query ).items.pluck :id
    end

    index = item_ids.index( @item.id  )

    @next = nil
    if index && index < item_ids.size - 1
      next_id = item_ids[index+1]
      @next = Item.find next_id
    end

    @prev = nil
    if index && index > 0
      prev_id = item_ids[index-1]
      @prev = Item.find prev_id
    end

    params = {}
    params[:q] = @query unless @query.empty?

    if @prev
      @prev_url = item_path params.merge(id: @prev.id)
    end

    if @next
      @next_url = item_path params.merge(id: @next.id)
      @next_image_url = @next.resized_url 'large'
    end

    @tags = @item.tags.map { |tag| tag.label }.join( ', ' )

    @title = "HyperCheese"
    @title = @tags + " - HyperCheese" unless @tags.empty?

    respond_to do |format|
      format.html
      format.json do
        item = @item.as_json
        item[:tags] = @item.tags.map &:id
        render json: item
      end
    end
  end

  # GET /items/:id/download
  def download
    @item = Item.find params[:id]
    send_file @item.full_path, type: File.mime_type?( @item.path )
  end

  # GET /items/download_warning
  def download_warning
    @event = Event.find params[:id]
    @size = 0
    @event.items.each do |item|
      @size += File.size item.full_path
    end
  end

  # POST /items/download
  def download_pack
    t = Tempfile.new 'cheese-photos'
    Zip::ZipOutputStream.open( t.path ) do |zip|
      items = []
      if params[:ids]
        params[:ids].split( ',' ).each do |id|
          id.gsub! /^item_/, ''
          item = Item.find id
          items.push item
        end
      end

      if params[:event]
        event = Event.find params[:event]
        ids = event.items.each
      end

      items.each do |item|
        title = File.basename item.full_path
        zip.put_next_entry title
        zip.print IO.read( item.full_path )
      end
    end

    send_file t.path, type: 'application/zip', filename: 'cheese-photos.zip'
  end

  # POST /items/tags
  def tags
    data = JSON.parse params[:data]
    data.each do |item_id,tags|
      item_id =~ /(\d+)/ or next
      Item.transaction do
        item = Item.find $1.to_i
        item.tags.clear
        tags.each do |tag_id,val|
          next unless val == true
          tag = Tag.find tag_id.to_i
          item.tags.push tag
        end
        item.save
      end
    end
    render text: "OK"
  end

  # PUT /items/:item_id/tags/:tag_id
  def add_tag
    item = Item.find params[:item_id]
    tag = Tag.find params[:tag_id]
    item.tags.push tag unless item.tags.member? tag
    item.save!

    render text: "OK"
  end

  def remove_tag
    item = Item.find params[:item_id]
    tag = Tag.find params[:tag_id]
    item.tags.delete tag
    item.save!

    render text: "OK"
  end
end
