module TagParser
  def self.parse string
    words = string.split /,/

    # trim
    words = words.map do |word|
      word.sub( /^\s+/, '' ).sub( /\s+$/, '' )
    end

    # remove empty strings
    words = words.select do |word|
      !word.empty?
    end

    tags = []
    invalid = []
    while word = words.shift
      tag = Tag.where( "label like ?", word ).first
      if tag
        tags << tag
        next
      end
      if word =~ /\s/
        words += word.split /\s+/
      else
        invalid << word
      end
    end

    return tags, invalid
  end

  def self.canonicalize string
    tags = parse string
    tags.map { |tag| tag.label }.join( ", " )
  end
end
