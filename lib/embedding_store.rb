class EmbeddingStore
  def initialize name, size
    @name = name
    @size = size
  end

  def path
    Rails.root + "embeddings/#{@name}-#{@size}.db"
  end

  def slurp
    File.binread path
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

  def each_with_index
    count = handle.size / (@size * 4)
    index = 0
    handle.seek 0
    blank = 0.chr * @size * 4
    while index < count
      data = handle.read @size * 4
      raise "Not expecting nil at #{index}" unless data

      if data != blank
        yield data, index
      end
      index += 1
    end
    count
  end

  # Returns [[distance, id], [distance, id], ...]
  def bulk_cosine_distance embedding, threshold
    path.open 'rb' do |f|
      return NativeFunctions.bulk_cosine_distance_mmap embedding, threshold, f.size, f.fileno
    end
  end

  private
  def handle
    @_handle ||= path.open("r+b")
  end
end
