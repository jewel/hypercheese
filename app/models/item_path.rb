class ItemPath < ActiveRecord::Base
  belongs_to :item
  BASE_PATH = File.join Rails.root, "originals"
  def full_path
    "#{BASE_PATH}/#{path}"
  end

end
