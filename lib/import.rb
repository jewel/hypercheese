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

  def self.by_path path
    path = Pathname.new( path ).cleanpath.to_s
    path = File.join Dir.pwd, path unless path =~ /\A\//

    if Object.const_defined? :EXCLUDE_REGEX
      EXCLUDE_REGEX.each do |regex|
        if path =~ regex
          warn "Excluding #{path.inspect} due to #{regex.inspect}"
          return nil
        end
      end
    else
      warn "Not excluding private files, no EXCLUDE REGEX defined" unless @warned
      @warned = true
    end

    raise "Strange path" unless path =~ /\.(\w+)\Z/
    ext = $1.downcase

    type = EXTS[ext]
    raise "File extension not supported" unless type
    raise "Empty file" unless File.size(path) > 0

    normalized_path = path.delete_prefix ItemPath::BASE_PATH + "/"
    partial_path = normalized_path.sub %r{\A(.*?)/}, ''
    source_path = $1
    source = Source.find_by_path source_path
    raise "No source set up for #{source_path}" unless source

    old = ItemPath.where(source: source).where( path: partial_path ).first
    if old
      item = old.item
      warn "Item already imported: #{partial_path}"
      if partial_path != old.path
        # MySQL case sensitivity issues
        warn "Case sensitivity problem: #{old.path.inspect} -> #{partial_path.inspect}"
      end

      load_metadata item, path, type
      item.save
    else
      md5 = Digest::MD5.file( path ).hexdigest

      old = Item.where( :md5 => md5 ).first
      if old
        old.paths.each do |item_path|
          next if File.exists? item_path.full_path
          warn "Alternate path #{item_path.path} no longer exists!"
          item_path.destroy
        end
        warn "#{partial_path} has same MD5 as #{old.paths.size} other files"
        item_path = ItemPath.new item: old, source: source, path: partial_path
        item_path.save

        return
      end
      warn "Creating #{partial_path}"

      item = Item.new

      item.published = source.default_published_state

      item.md5 = md5

      item.variety = type
      item.code = SecureRandom.urlsafe_base64 8

      # We'll override "taken" later, but if we don't set it at all then the
      # files will not show up where the user expects while they are being
      # imported.
      item.taken = File.mtime path

      item.save!

      item_path = ItemPath.new item: item, source: source, path: partial_path
      item_path.save!

      item.schedule_jobs
    end

    item
  end
end
