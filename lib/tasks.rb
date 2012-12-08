module Tasks
  def self.update_tag_counts
    count = 0
    Tag.all.each do |tag|
      old = tag.item_count || 0
      tag.item_count = tag.items.count
      next if old == tag.item_count
      count += tag.item_count - old
      puts "#{tag.label}: #{old < tag.item_count ? '+' : '-'}#{(old-tag.item_count).abs}"
      tag.save
    end
    puts "Total changes: #{count}"
  end

  def self.update_tag_icons
    Tag.all.each do |tag|
      old = tag.icon

      icon = Search.execute( "only " + tag.label + " orient:port type:photo").first
      icon ||= Search.execute( "only " + tag.label + " type:photo" ).first
      icon ||= Search.execute( tag.label + " type:photo" ).first
      next unless icon

      next if tag.icon == icon

      puts "#{tag.label}"

      tag.icon = icon

      tag.save
    end

  end
end

