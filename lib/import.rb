require 'digest/md5'

module Import
  EXTS = {
    'jpg' => 'photo',
    'jpeg' => 'photo',
    'tiff' => 'photo',
    'tif' => 'photo',
    'png' => 'photo',
    'avi' => 'video',
    'mov' => 'video',
    'mpg' => 'video',
    'mts' => 'video',
    'mp4' => 'video',
    'mkv' => 'video',
    'vob' => 'video',
    'dv' => 'video',
    'wmv' => 'video',
  }

  def self.by_blob blob
    source = Source.find_by device: blob.device
    raise "No source set up for device #{blob.device.id}" unless source

    import_item(
      source: source,
      partial_path: blob.path,
      file_path: blob.download_to_temp,
      mtime: blob.mtime
    )
  end

  def self.by_path path
    path = Pathname.new(path).cleanpath.to_s
    path = File.join Dir.pwd, path unless path =~ /\A\//

    normalized_path = path.delete_prefix ItemPath::BASE_PATH + "/"
    partial_path = normalized_path.sub %r{\A(.*?)/}, ''
    source_path = $1
    source = Source.find_by_path source_path
    raise "No source set up for #{source_path}" unless source

    import_item(
      source: source,
      partial_path: partial_path,
      file_path: path,
      mtime: File.mtime(path)
    )
  end

  private

  def self.import_item source:, partial_path:, file_path:, mtime:
    if Object.const_defined? :EXCLUDE_REGEX
      EXCLUDE_REGEX.each do |regex|
        if partial_path =~ regex
          warn "Excluding #{partial_path.inspect} due to #{regex.inspect}"
          return nil
        end
      end
    else
      warn "Not excluding private files, no EXCLUDE REGEX defined" unless @warned
      @warned = true
    end

    raise "Strange path" unless partial_path =~ /\.(\w+)\Z/
    ext = $1.downcase

    type = EXTS[ext]
    raise "File extension not supported" unless type
    raise "Empty file" unless File.size(file_path) > 0

    old = ItemPath.where(source: source).where(path: partial_path).first
    if old
      item = old.item
      warn "Item already imported: #{partial_path}"
      if partial_path != old.path
        # MySQL case sensitivity issues
        warn "Case sensitivity problem: #{old.path.inspect} -> #{partial_path.inspect}"
      end
      return item
    end

    # Check for duplicate content
    md5 = Digest::MD5.file(file_path).hexdigest
    old = Item.where(md5: md5).first
    if old
      warn "#{partial_path} has same MD5 as #{old.paths.size} other files"
      item_path = ItemPath.new item: old, source: source, path: partial_path
      item_path.save
      return old
    end

    warn "Creating #{partial_path}"
    item = Item.new
    item.published = source.default_published_state
    item.md5 = md5
    item.variety = type
    item.code = SecureRandom.urlsafe_base64 8
    item.taken = mtime
    item.save!

    item_path = ItemPath.new item: item, source: source, path: partial_path
    item_path.save!

    item.schedule_jobs
    item
  end
end
