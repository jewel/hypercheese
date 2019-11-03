class ItemPath < ActiveRecord::Base
  belongs_to :item
  belongs_to :source

  BASE_PATH = File.join Rails.root, "originals"
  def full_path
    "#{BASE_PATH}/#{path_with_source}"
  end

  def path_with_source
    "#{source.path}/#{path}"
  end
end
