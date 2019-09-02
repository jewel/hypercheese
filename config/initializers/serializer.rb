ActiveModel::Serializer.config.tap do |c|
  c.embed = :ids
  c.adapter = :json
end
