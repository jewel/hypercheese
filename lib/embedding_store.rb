class EmbeddingStore
  def initialize name, size
    @name = name
    @size = size
  end

  def path
    Rails.root + "embeddings/#{@name}-#{@size}.db"
  end

  def get index
    handle.seek index * @size * 4
    data = handle.read @size * 4
    return nil unless data
    raise "Not enough data, read #{data.bytesize} bytes but want #{@size * 4} bytes" unless data.bytesize == @size * 4
    data
  end

  def put index, data
    raise "Data is wrong size: #{data.size} != #{@size}" unless data.size == @size
    handle.seek index * @size * 4
    record = data.pack 'f*'
    raise "Record is wrong size" unless record.size == @size * 4
    handle.write record
  end

  def has index
    embedding = get index
    return false if embedding == nil
    return false if embedding == 0.chr * @size * 4
    true
  end

  private
  def handle
    @_handle ||= File.open path, "r+b"
  end
end
