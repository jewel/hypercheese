LIMIT = 20

xml.instruct!
xml.rss "version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.channel do
    xml.title   "Media-Site"
    xml.description "Awesome photos."
    xml.link    url_for(:search_index)

    i = 0
    @items.each do |item|
      xml.item do
        xml.title   item.tags.map { |tag| tag.label }.join ', '
        xml.description image_tag "/resized/small/#{item.id}.jpg"
        xml.pubDate item.taken.to_s(:rfc822)
        xml.link  url_for(:item_view, :id => item.id )
      end
      i += 1
      break if i >= LIMIT
    end
  end
end
