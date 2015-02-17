require_dependency 'tag_parser'

class Search
  def initialize query
    @query = query
  end

  def items
    execute
    @items
  end

  def invalid
    execute
    @invalid
  end

  def sort_by
    execute
    @sort_by
  end

  def tags
    execute
    @tags
  end

  def execute
    return if @executed

    filter = [ '1=1' ]

    query = @query.dup

    opts = {}
    query.gsub! /\s?\b(\w+):(\w*)\b/ do
      opts[$1.downcase.to_sym] = $2.downcase
      ''
    end

    case opts[:orientation] || opts[:orient]
    when /^land/
      filter = [ 'height < width' ]
    when /^port/
      filter = [ 'height > width' ]
    when /^square/
      filter = [ 'height = width' ]
    else
    end

    if opts[:type]
      filter << [:type, opts[:type].downcase]
    end

    items = Item.where *filter

    query.gsub! /^\s+/, ''
    query.gsub! /\s+$/, ''

    if query.sub! /^(just|only)\s+/i, ''
      opts[:only] = true
    end

    if query.sub! /^any\s+/i, ''
      opts[:any] = true
    end

    [ :reverse, :untagged, :comments ].each do |keyword|
      if query.sub! /\b#{keyword}\b/i, ''
        opts[keyword] = true
      end
    end

    if query.sub! /\breverse\b/i, ''
      opts[:reverse] = true
    end

    if query.sub! /\buntagged\b/i, ''
      opts[:untagged] = true
    end

    opts[:year] = opts[:year].split /,/ if opts[:year]

    query.gsub! /\b(\d\d\d\d)\b/ do
      opts[:year] ||= []
      opts[:year] << $1.to_i
      ''
    end

    raise "Invalid 'by'" if opts[:by] && opts[:by] !~ /\A\w+\Z/
    @sort_by = (opts[:by] || :taken).to_sym
    @items = Item.none
    @invalid = []
    @tags = []

    unless query.empty?
      tags, invalid = TagParser.parse query
      @tags = tags
      @invalid = @invalid

      unless invalid.empty?
        @executed = true
        return
      end

      if opts[:any]
        items = items.where 'id in ( select item_id from item_tags where tag_id IN ? )', tags.map { |t| t.id }
      else
        tags.each do |tag|
          items = items.where 'id in ( select item_id from item_tags where tag_id = ? )', tag.id
        end
      end

      if opts[:only]
        items = items.where 'id not in ( select item_id from item_tags where tag_id not in ? )', tags.map { |t| t.id }
      end
    end

    if opts[:comments]
      items = items.where 'id in ( select item_id from comments )'
    end

    if opts[:untagged]
      items = items.where 'id not in ( select item_id from item_tags )'
    end

    if opts[:source]
      items = items.where 'path like ?', opts[:source] + "/%"
    end

    if opts[:path]
      items = items.where 'path like ?', "%#{opts[:path]}%"
    end

    if opts[:year]
      items = items.where 'year(taken) in ?', opts[:year]
    end

    if opts[:reverse]
      items = items.order @sort_by
    else
      items = items.order "#@sort_by desc"
    end

    @items = items
    @executed = true
  end
end
