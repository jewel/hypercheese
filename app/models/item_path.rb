class ItemPath < ActiveRecord::Base
  belongs_to :item
  belongs_to :source

  BASE_PATH = File.join Rails.root, "originals"

  # Check if the file has changed based on mtime and size
  def file_changed?
    current_mtime, current_size = get_current_file_stats
    return false unless current_mtime && current_size
    
    # If we don't have stored mtime/size, assume it's changed
    return true unless mtime && size
    
    # Compare current values with stored values
    current_mtime != mtime || current_size != size
  end

  # Get the current file stats (mtime and size)
  def get_current_file_stats
    path = full_path
    return [nil, nil] unless File.exist?(path)
    
    stat = File.stat(path)
    [stat.mtime, stat.size]
  end

  # Update the stored file stats
  def update_file_stats!
    current_mtime, current_size = get_current_file_stats
    return unless current_mtime && current_size
    
    update!(mtime: current_mtime, size: current_size)
  end

  # Check if this file path still exists
  def file_exists?
    File.exist?(full_path)
  end

  def full_path
    if source.device
      blob = CheeseBlob.find_by!(
        user: source.user,
        device: source.device,
        path: path
      )
      blob.download_to_temp
    else
      "#{BASE_PATH}/#{path_with_source}"
    end
  end

  def path_with_source
    "#{source.path}/#{path}"
  end
end
