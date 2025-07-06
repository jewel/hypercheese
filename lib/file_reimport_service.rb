require 'digest/md5'
require 'securerandom'

class FileReimportService
  attr_reader :changed_files, :split_items, :reimported_items

  def initialize
    @changed_files = []
    @split_items = []
    @reimported_items = []
  end

  # Check all files for changes and handle reimport
  def check_and_reimport_all
    puts "Checking all files for changes..."
    
    ItemPath.includes(:item, :source).find_each do |item_path|
      check_and_reimport_item_path(item_path)
    end

    puts "File reimport summary:"
    puts "  Changed files: #{@changed_files.count}"
    puts "  Split items: #{@split_items.count}"
    puts "  Reimported items: #{@reimported_items.count}"
    
    {
      changed_files: @changed_files,
      split_items: @split_items,
      reimported_items: @reimported_items
    }
  end

  # Check a specific item path for changes
  def check_and_reimport_item_path(item_path)
    return unless item_path.file_changed?

    @changed_files << item_path
    puts "File changed: #{item_path.path_with_source}"

    # Get all paths for this item
    all_item_paths = item_path.item.item_paths.to_a
    
    if all_item_paths.count == 1
      # Only one path, just reimport the existing item
      reimport_existing_item(item_path)
    else
      # Multiple paths, check if others still exist
      other_paths = all_item_paths - [item_path]
      existing_other_paths = other_paths.select(&:file_exists?)
      
      if existing_other_paths.any?
        # Other paths still exist, split into new item
        split_to_new_item(item_path)
      else
        # No other paths exist, reimport the existing item
        reimport_existing_item(item_path)
      end
    end
  end

  private

  def reimport_existing_item(item_path)
    puts "  Reimporting existing item: #{item_path.item.id}"
    
    # Update file stats
    item_path.update_file_stats!
    
    # Re-calculate MD5 and update item
    file_path = item_path.full_path
    new_md5 = Digest::MD5.file(file_path).hexdigest
    
    # Check if MD5 has changed
    if item_path.item.md5 != new_md5
      puts "    MD5 changed from #{item_path.item.md5} to #{new_md5}"
      
      # Check if another item already has this MD5
      existing_item = Item.where(md5: new_md5).where.not(id: item_path.item.id).first
      if existing_item
        # Another item has this MD5, merge paths
        puts "    Merging with existing item #{existing_item.id}"
        item_path.update!(item: existing_item)
        return
      else
        # Update the MD5
        item_path.item.update!(md5: new_md5)
      end
    end
    
    # Re-extract metadata and reschedule jobs
    item_path.item.update!(taken: File.mtime(file_path))
    item_path.item.schedule_jobs_with_force_regeneration
    
    @reimported_items << item_path.item
  end

  def split_to_new_item(item_path)
    puts "  Splitting into new item: #{item_path.path_with_source}"
    
    # Create new item for the changed file
    file_path = item_path.full_path
    new_md5 = Digest::MD5.file(file_path).hexdigest
    
    # Check if another item already has this MD5
    existing_item = Item.where(md5: new_md5).first
    if existing_item
      puts "    Moving to existing item with same MD5: #{existing_item.id}"
      item_path.update!(item: existing_item)
      item_path.update_file_stats!
      return
    end
    
    # Get file extension and type
    ext = File.extname(item_path.path).downcase.delete('.')
    type = Import::EXTS[ext]
    
    unless type
      puts "    Skipping unsupported file type: #{ext}"
      return
    end
    
    # Create new item
    new_item = Item.create!(
      published: item_path.source.default_published_state,
      md5: new_md5,
      variety: type,
      code: SecureRandom.urlsafe_base64(8),
      taken: File.mtime(file_path)
    )
    
    # Move the item path to the new item
    item_path.update!(item: new_item)
    item_path.update_file_stats!
    
    # Schedule jobs for the new item
    new_item.schedule_jobs
    
    @split_items << {
      old_item_id: item_path.item.id,
      new_item: new_item,
      moved_path: item_path
    }
  end
end