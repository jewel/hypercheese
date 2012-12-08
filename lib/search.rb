require_dependency 'tag_parser'

module Search
  def self.execute query
    r,i = execute_with_invalid query
    r
  end

  def self.execute_with_invalid query
    filter = [ '1=1' ]

    query = query.dup

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


    invalid = []

    unless query.empty?
      tags, invalid = TagParser.parse query

      if opts[:any]
        items = items.all :conditions => [
          'id in ( select item_id from item_tags where tag_id IN ? )',
          tags.map { |t| t.id }
        ]
      else
        tags.each do |tag|
          items = items.all :conditions => [
            'id in ( select item_id from item_tags where tag_id = ? )', tag.id
          ]
        end
      end

      if opts[:only]
        items = items.all :conditions => [ 'id not in ( select item_id from item_tags where tag_id not in ? )', tags.map { |t| t.id } ]
      end
    end

    if opts[:comments]
      items = items.all :conditions => [ 'id in ( select item_id from comments )' ]
    end

    if opts[:untagged]
      items = items.all :conditions => [ 'id not in ( select item_id from item_tags )' ]
    end

    if opts[:source]
      items = items.all :conditions => [ 'path like ?', opts[:source] + "/%" ]
    end

    if opts[:path]
      items = items.all :conditions => [ 'path like ?', "%#{opts[:path]}%" ]
    end

    if opts[:year]
      items = items.all :conditions => [ 'year(taken) in ?', opts[:year] ]
    end


    if opts[:by]
      raise "Invalid 'by'" unless opts[:by] =~ /\A\w+\Z/
      if opts[:reverse]
        items = items.order "#{opts[:by]} desc"
      else
        items = items.sort_by opts[:by]
      end
    else
      if opts[:reverse]
        items = items.order "taken"
      else
        items = items.order "taken desc"
      end
    end

    return items, invalid
  end

end
