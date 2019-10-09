class SharedItemSerializer < ActiveModel::Serializer
  attributes :id, :variety, :filename, :taken, :exif, :tags_with_labels
  has_many :comments, include: true

  def tags_with_labels
    object.tags.map do |tag|
      [ tag.icon_item_id, tag.label ]
    end
  end

  def comments
    object.comments.order :created_at
  end

  def filename
    File.basename object.path
  end
end
