class SearchQueryFormatter
  def self.format_query(query_hash)
    return '' if query_hash.blank?
    
    parts = []
    
    # Handle tags
    if query_hash[:tags].present?
      tag_ids = query_hash[:tags].map(&:to_i)
      tags = Tag.where(id: tag_ids).pluck(:label)
      parts.concat(tags) if tags.any?
    end
    
    # Handle various query options
    %w[clip not comment path in near].each do |key|
      if query_hash[key.to_sym].present?
        value = query_hash[key.to_sym]
        if key == 'clip'
          parts << (value.include?(' ') ? "\"#{value}\"" : value)
        else
          parts << "#{key}:#{value}"
        end
      end
    end
    
    # Handle boolean flags
    %w[any only reverse untagged unjudged has_comments starred faces].each do |key|
      if query_hash[key.to_sym] == true
        parts << key
      end
    end
    
    # Handle arrays
    %w[year month day source item].each do |key|
      if query_hash[key.to_sym].present?
        value = query_hash[key.to_sym]
        if value.is_a?(Array)
          parts << "#{key}:#{value.join(',')}"
        else
          parts << "#{key}:#{value}"
        end
      end
    end
    
    # Handle other single values
    %w[orientation type sort shared visibility threshold duration age miles].each do |key|
      if query_hash[key.to_sym].present?
        parts << "#{key}:#{query_hash[key.to_sym]}"
      end
    end
    
    parts.join(' ')
  end
end