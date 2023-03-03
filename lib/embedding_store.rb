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
    raise "Not enough data, read #{data.bytesize} bytes but want #{@size * 4} bytes" unless data.bytesize == @size * 4
    data
  end

  def put index, data
    raise "Data is wrong size: #{data.size} != #{@size}" unless data.size == @size
    handle.seek index * @size * 4
    handle.write data.pack 'E*'
  end

  def has index
    return false if handle.size <= index * @size * 4
    return false if get(index) == 0.chr * @size * 4
    true
  end

  private
  def handle
    @_handle ||= File.open path, "a+b"
  end
end
