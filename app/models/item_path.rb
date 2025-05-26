class ItemPath < ActiveRecord::Base
  belongs_to :item
  belongs_to :source

  BASE_PATH = File.join Rails.root, "originals"

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
