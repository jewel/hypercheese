require_relative 'embedding_store'
require 'net/http'

class Search
  def initialize query
    @query = query
    @pluckable = true
  end

  def items
    execute
    @items
  end

  def ids
    res = if @pluckable
      items.pluck :id
    else
      items.map { |item| item.id }
    end

    return res unless @query[:sort] =~ /^clip/
    res = Set.new res
    @clip_ids.select do |id|
      res.member? id
    end
  end

  def execute
    return if @executed

    items = Item.where deleted: false

    published = case @query[:visibility]
    when 'unknown'
      nil
    when 'unpublished'
      false
    else
      true
    end
    items = items.where published: published

    if !published
      sources = Source.where user_id: @query[:current_user].id
      items = items.where "id in ( select item_id from item_paths where source_id IN (?))", sources.map(&:id)
    end

    case @query[:orientation]
    when 'landscape'
      items = items.where 'height < width'
    when 'portrait'
      items = items.where 'height > width'
    when 'square'
      items = items.where 'height = width'
    else
    end

    if @query[:duration]
      @query[:type] = 'video'
      if @query[:duration] =~ /\A(\d+)-(\d+)\z/
        items = items.where ["round(duration) between ? and ?", $1, $2]
      elsif @query[:duration] =~ /\A(\d+)\+\z/
        items = items.where ["round(duration) >= ?", $1]
      elsif @query[:duration] =~ /\A(\d+)\z/
        items = items.where ["round(duration) = ?", $1]
      elsif @query[:duration] =~ /\A-(\d+)\z/
        items = items.where ["round(duration) <= ?", $1]
      else
        raise "Invalid duration: #{@query[:duration].inspect}"
      end
    end

    if @query[:type]
      items = items.where variety: @query[:type].to_s
    end

    hidden_tag = Tag.where( label: 'Hidden' ).first
    if hidden_tag
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', hidden_tag.id ]
    end

    tag_ids = (@query[:tags] || []).map(&:to_i)
    delete_tag = Tag.where( label: 'delete' ).first
    if delete_tag && !tag_ids.member?( delete_tag.id )
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', delete_tag.id ]
    end
    @items = Item.none

    if @query[:faces]
      tag_ids.each do |id|
        items = items.where 'id in (
          select item_id from faces where cluster_id in (
            select id from faces where tag_id = ?
          )
        )', id
      end
    elsif @query[:any]
      items = items.where 'id in ( select item_id from item_tags where tag_id IN (?) )', descendants(tag_ids)
    else
      tag_ids.each do |id|
        items = items.where 'id in ( select item_id from item_tags where tag_id IN (?) )', descendants([id])
      end
    end

    if @query[:only]
      items = items.where 'id not in ( select item_id from item_tags where tag_id not in (?) )', tag_ids
    end

    if @query[:not]
      tag = Tag.find_by_label @query[:not]
      if tag
        items = items.where 'id not in ( select item_id from item_tags where tag_id in (?))', descendants([tag.id]) - tag_ids
      end
    end

    if @query[:has_comments]
      items = items.where 'id in ( select item_id from comments )'
    end

    if @query[:comment]
      items = items.where ['id in ( select item_id from comments where text like ? )', "%#{@query[:comment]}%" ]
    end

    if @query[:in]
      location = @query[:in].gsub /[-_]/, ' '
      items = items.where ['id in ( select item_id from item_locations where location_id in ( select id from locations where name = ? ) )', location]
    end

    if @query[:near]
      lat, lon = @query[:near].split /,/
      n_miles = 1.0
      if @query[:miles]
        n_miles = @query[:miles].to_f
      end

      earth_radius_miles = 3960

      given_coordinate = RGeo::Geographic.spherical_factory(srid: 4326).point(lon, lat)

      lat_degree_distance = n_miles / 69.0 # 1 degree of latitude is approximately 69 miles
      lon_degree_distance = (n_miles / (Math.cos(given_coordinate.latitude * Math::PI / 180) * 69)).abs
      min_lat = given_coordinate.latitude - lat_degree_distance
      max_lat = given_coordinate.latitude + lat_degree_distance
      min_lon = given_coordinate.longitude - lon_degree_distance
      max_lon = given_coordinate.longitude + lon_degree_distance

      items = items.where("latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?", min_lat, max_lat, min_lon, max_lon)
    end

    if @query[:untagged]
      items = items.where 'id not in ( select item_id from item_tags )'
    end

    if @query[:unjudged] && @query[:current_user]
      items = items.where 'id not in ( select item_id from ratings where user_id = ? )', @query[:current_user].id
    end

    if @query[:starred] && @query[:current_user]
      items = items.where 'id in ( select item_id from stars where user_id = ? )', @query[:current_user].id
    end

    if @query[:source]
      sources = @query[:source].map do |s|
        source = Source.where( label: s.to_s ).first
        source ||= Source.where( path: s.to_s ).first
      end
      sources = sources.compact

      unless sources.empty?
        items = items.where "id in ( select item_id from item_paths where source_id IN (?))", sources.map(&:id)
      end
    end

    if @query[:item]
      ids = expand_list @query[:item]
      items = items.where 'id in (?)', ids
    end

    if @query[:shared]
      share = Share.find_by_code( @query[:shared].to_s )
      items = items.where "id in (?)", share.item_ids
    end

    if @query[:path]
      items = items.where [ 'id in ( select item_id from item_paths where path like ? )', "%#{@query[:path]}%" ]
    end

    if @query[:year]
      items = items.where 'year(taken) in (?)', @query[:year].map(&:to_i)
    end

    if @query[:month]
      items = items.where 'month(taken) in (?)', @query[:month].map(&:to_i)
    end

    if @query[:day]
      items = items.where 'day(taken) in (?)', @query[:day].map(&:to_i)
    end

    if @query[:age]
      tag = Tag.where(id: tag_ids).where.not(birthday: nil).order('birthday desc').first
      age = @query[:age].to_i
      if tag
        birthday = tag.birthday
        start = birthday + age.years
        finish = start + 1.years
        items = items.where('taken between ? AND ?', start, finish)
      end
    end

    if @query[:clip]
      string = @query[:clip].join ' '
      embedding = clip_embedding string
      threshold = 0.18
      if @query[:threshold]
        threshold = @query[:threshold].to_f / 100
      end
      @clip_ids = clip_search embedding, threshold
      items = items.where id: @clip_ids
      @query[:sort] ||= 'clip'
    end

    raise "Invalid 'by'" if @query[:sort] && @query[:sort] !~ /\A\w+\Z/
    @query[:sort] = 'rand()' if @query[:sort] == 'random'

    if @query[:sort] == 'aesthetics'
      @query[:sort] = 'aesthetics_score'
      items = items.where('aesthetics_score is not null')
    end

    if @query[:sort] == 'age'
      age = "timestampdiff( second, (
          select tags.birthday
          from tags join item_tags on tags.id = item_tags.tag_id
          where item_id = items.id
            and birthday is not null
          order by tags.birthday desc limit 1
        ), items.taken) AS age
      "
      items = items.select("*, #{age}").having( "age is not null and age >= 0" )
      @query[:reverse] = !@query[:reverse]
      @pluckable = false
    end

    @query[:sort] ||= "taken"

    unless @query[:reverse]
      @query[:sort] += " desc"
    end

    @query[:sort] += ", id"
    @query[:sort] += " desc" unless @query[:reverse]

    unless @query[:sort] =~ /^clip/
      items = items.order @query[:sort]
    end

    @items = items
    @executed = true
  end

  def expand_list groups
    ids = []
    groups.each do |seq|
      start, finish = seq.split '-'
      finish ||= start

      # Check for partial digit shorthand
      # Example: 1000-2 as an encoding for 1000-1002
      if finish.to_i < start.to_i
        finish = start[0...-finish.size] + finish
      end

      ids.concat (start.to_i..finish.to_i).to_a
    end
    ids
  end

  def descendants tag_ids
    if !@descendants
      @descendants = Hash.new { |h, k| h[k] = [] }
      Tag.all.each do |tag|
        parent = tag
        while parent = parent.parent
          @descendants[parent.id] << tag.id
        end
      end
    end
    tag_ids + tag_ids.map { |_| @descendants[_] || [] }.flatten
  end

  private

  def clip_embedding text
    uri = URI( 'http://face:7860/run/extract' )

    res = nil

    # FIXME switch to HTTParty
    Net::HTTP.start uri.host, uri.port do |http|
      req = Net::HTTP::Post.new uri, 'Content-Type' => 'application/json'
      req.body = { data: [text] }.to_json
      str = http.request(req).body
      res = JSON.parse str, symbolize_names: true
    end

    res = res[:data][0]
    res[:embedding]
  end

  def clip_search embedding, threshold
    store = EmbeddingStore.new "clip", 768

    raw = embedding.pack 'f*'

    output = store.bulk_cosine_distance raw, threshold

    # Also search videos
    video_store = EmbeddingStore.new "video-clip", 768
    frames = video_store.bulk_cosine_distance raw, threshold
    frame_ids = frames.map { _1.last }
    frame_scores = {}
    frames.each do |score, frame_id|
      frame_scores[frame_id] = score
    end

    item_scores = {}
    frame_ids = ClipFrame.where(id: frame_ids).pluck(:id, :item_id).each do |frame_id, item_id|
      score = frame_scores[frame_id]
      item_scores[item_id] ||= []
      item_scores[item_id] << score
    end

    item_scores.each do |item_id, scores|
      output.push [scores.max, item_id]
    end

    output.sort_by! { -_1.first }
    output.map { _1.last }
  end
end
