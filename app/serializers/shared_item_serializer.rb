class SharedItemSerializer < ActiveModel::Serializer
  attributes :id, :variety, :filename

  def filename
    File.basename object.path
  end
end
