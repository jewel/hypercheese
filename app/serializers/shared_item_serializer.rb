class SharedItemSerializer < ActiveModel::Serializer
  attributes :id, :code, :variety, :filename, :taken, :exif, :tags_with_labels
  has_many :comments, include: true

  def exif
    object.exif&.as_json&.except "user_comment"
  end

  def tags_with_labels
    object.tags.map do |tag|
      [ tag.icon&.id, tag.icon&.code, tag.label ]
    end
  end

  def comments
    object.comments.order :created_at
  end

  def filename
    File.basename object.path
  end
end
