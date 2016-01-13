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

    items = Item.where deleted: false

    query = @query.dup

    opts = {}
    query.gsub! /\s?\b(\w+):([-\w]*)\b/ do
      opts[$1.downcase.to_sym] = $2.downcase
      ''
    end

    case opts[:orientation] || opts[:orient]
    when /^land/
      items = items.where 'height < width'
    when /^port/
      items = items.where 'height > width'
    when /^square/
      items = items.where 'height = width'
    else
    end

    query.gsub! /\bvideos?\b/ do
      opts[:type] = 'video'
      ''
    end

    query.gsub! /\bphotos?\b/ do
      opts[:type] = 'photo'
      ''
    end

    if opts[:type]
      items = items.where variety: opts[:type].downcase
    end

    query.gsub! /^\s+/, ''
    query.gsub! /\s+$/, ''

    if query.sub! /^(just|only)\s+/i, ''
      opts[:only] = true
    end

    if query.sub! /^any\s+/i, ''
      opts[:any] = true
    end

    [ :reverse, :untagged, :has_comments ].each do |keyword|
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

    months = %w{
      jan feb mar apr may jun jul aug sep oct nov dec
      january
      february
      march
      april
      may
      june
      july
      august
      september
      october
      november
      december
    }

    months.each_with_index do |month,index|
      month_num = (index % 12) + 1
      query.gsub! /\b#{month}\b/i do
        opts[:month] ||= []
        opts[:month] << month_num
        ''
      end
    end

    hidden_tag = Tag.where( label: 'Hidden' ).first
    if hidden_tag
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', hidden_tag.id ]
    end

    delete_tag = Tag.where( label: 'delete' ).first
    if delete_tag && query !~ /\bdelete\b/
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', delete_tag.id ]
    end

    raise "Invalid 'by'" if opts[:by] && opts[:by] !~ /\A\w+\Z/
    if opts[:by]
      opts[:by] = 'md5' if opts[:by] =~ /^rand/i
    end
    @sort_by = (opts[:by] || :taken).to_sym
    @items = Item.none
    @invalid = []
    @tags = []

    unless query.empty?
      tags, invalid = TagParser.parse query
      @tags = tags
      @invalid = invalid

      unless invalid.empty?
        @executed = true
        return
      end

      if opts[:any]
        items = items.where 'id in ( select item_id from item_tags where tag_id IN (?) )', tags.map { |t| t.id }
      else
        tags.each do |tag|
          items = items.where 'id in ( select item_id from item_tags where tag_id = ? )', tag.id
        end
      end

      if opts[:only]
        items = items.where 'id not in ( select item_id from item_tags where tag_id not in (?) )', tags.map { |t| t.id }
      end
    end

    if opts[:has_comments]
      items = items.where 'id in ( select item_id from comments )'
    end

    if opts[:comment]
      items = items.where ['id in ( select item_id from comments where text like ? )', "%#{opts[:comment]}%" ]
    end

    if opts[:untagged]
      items = items.where 'id not in ( select item_id from item_tags )'
    end

    if opts[:source]
      source = Source.where( label: opts[:source] ).first
      source ||= Source.where( path: opts[:source] ).first
      if source
        items = items.where 'id in ( select item_id from item_paths where path like ?)', "#{source.path}/%"
      else
        @invalid << "source:#{opts[:source]}"
      end
    end

    if opts[:path]
      items = items.where [ 'id in ( select item_id from item_paths where path collate utf8_general_ci like ? )', "%#{opts[:path]}%" ]
    end

    if opts[:year]
      items = items.where 'year(taken) in (?)', opts[:year]
    end

    if opts[:month]
      items = items.where 'month(taken) in (?)', opts[:month]
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
