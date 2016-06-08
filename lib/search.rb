class Search
  def initialize query
    @query = query
  end

  def items
    execute
    @items
  end

  def execute
    return if @executed

    items = Item.where deleted: false

    case @query[:orientation]
    when 'landscape'
      items = items.where 'height < width'
    when 'portrait'
      items = items.where 'height > width'
    when 'square'
      items = items.where 'height = width'
    else
    end

    if @query[:type]
      items = items.where variety: @query[:type].to_s
    end

    hidden_tag = Tag.where( label: 'Hidden' ).first
    if hidden_tag
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', hidden_tag.id ]
    end

    delete_tag = Tag.where( label: 'delete' ).first
    if delete_tag && !@query.member?( delete_tag )
      items = items.where [ 'id not in ( select item_id from item_tags where tag_id = ?)', delete_tag.id ]
    end

    raise "Invalid 'by'" if @query[:by] && @query[:by] !~ /\A\w+\Z/
    if @query[:by]
      @query[:by] = 'md5' if @query[:by] == 'random'
    end
    sort_by = (@query[:by] || :taken).to_sym
    @items = Item.none

    if @query[:any]
      items = items.where 'id in ( select item_id from item_tags where tag_id IN (?) )', @query[:tags].map { |t| t.id }
    else
      @query[:tags].each do |tag|
        items = items.where 'id in ( select item_id from item_tags where tag_id = ? )', tag.id
      end
    end

    if @query[:only]
      items = items.where 'id not in ( select item_id from item_tags where tag_id not in (?) )', @query[:tags].map { |t| t.id }
    end

    if @query[:has_comments]
      items = items.where 'id in ( select item_id from comments )'
    end

    if @query[:comment]
      items = items.where ['id in ( select item_id from comments where text like ? )', "%#{@query[:comment]}%" ]
    end

    if @query[:untagged]
      items = items.where 'id not in ( select item_id from item_tags )'
    end

    if @query[:source]
      sources = @query[:source].map do |s|
        source = Source.where( label: s.to_s ).first
        source ||= Source.where( path: s.to_s ).first
      end
      sources = sources.compact

      unless sources.empty?
        query = []
        sources.size.times do
          query << "path like ?"
        end
        sources.map! { |_| "#{_.path}/%" }
        items = items.where "id in ( select item_id from item_paths where #{query.join ' or '})", sources
      end
    end

    if @query[:item]
      items = items.where 'id in (?)', @query[:item]
    end

    if @query[:path]
      items = items.where [ 'id in ( select item_id from item_paths where path collate utf8_general_ci like ? )', "%#{@query[:path]}%" ]
    end

    if @query[:year]
      items = items.where 'year(taken) in (?)', @query[:year].map(&:to_i)
    end

    if @query[:month]
      items = items.where 'month(taken) in (?)', @query[:month].map(&:to_i)
    end

    if @query[:reverse]
      items = items.order sort_by
    else
      items = items.order "#{sort_by} desc"
    end

    @items = items
    @executed = true
  end
end
