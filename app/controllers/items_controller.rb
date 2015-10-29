require_dependency 'search'
require 'digest'

class ItemsController < ApplicationController
  respond_to :json

  def index
    search_key = params[:search_key]
    path = Rails.root.join('tmp/searches').join search_key if search_key

    if search_key == '' || path && !File.exists?( path )
      search = Search.new params[:query] || ''
      ids = search.items.pluck(:id)
      str = ids.join ','
      search_key = Digest::MD5.hexdigest str
      dir = Rails.root.join('tmp/searches')
      Dir.mkdir dir unless File.exists? path
      path = "#{dir}/#{search_key}"
      temp = path + ".#$$.tmp"
      File.binwrite temp, str
      File.rename temp, path
    end

    raise "Invalid key" unless search_key =~ /\A[a-f0-9]{32}\Z/

    str = File.binread path
    ids = str.split ','

    limit = (params[:limit] || 1000).to_i
    offset = (params[:offset] || 0).to_i

    subset = ids.slice offset, limit

    res = Item.includes(:comments, :tags).find subset

    # `find` returns unordered, sort according to desired order
    items_by_id = {}
    res.each do |item|
      items_by_id[item.id] = item
    end

    res = subset.map do |item_id|
      items_by_id[item_id.to_i]
    end

    render json: res, each_serializer: ItemSerializer, meta: { search_key: search_key, total: ids.size }
  end

  def show
    render json: item
  end

  def add_tags
    items = nil

    Item.transaction do
      tags = Tag.find item_tag_params[:tags]
      items = Item.includes(:tags).find item_tag_params[:items]

      items.each do |item|
        tags.each do |tag|
          next if item.tags.member? tag
          item.tags.push tag
        end
      end
    end

    render json: items, each_serializer: ItemSerializer
  end

  def remove_tag
    items = nil
    Item.transaction do
      tag = Tag.find params[:tag].to_i
      items = Item.includes(:tags).find item_tag_params[:items]

      items.each do |item|
        next unless item.tags.member? tag
        item.tags.delete tag
      end
    end

    render json: items, each_serializer: ItemSerializer
  end

  include ActionController::Streaming
  include Zipline

  def download
    ids = params[:ids].split(/,/).map { |_| _.to_i }
    items = Item.where id: ids

    if items.size == 1
      return send_file items.first.full_path
    end

    files = items.map do |item|
      path = File.realpath item.full_path
      [File.open(path, 'rb'), File.basename(item.full_path)]
    end

    zipline files, "#{files.size}-from-hypercheese.zip"
  end

  private
  def item
    Item.find params[:id].to_i
  end

  def item_tag_params
    params.permit items: [], tags: []
  end
end
