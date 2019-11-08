class Source < ActiveRecord::Base
  has_many :item_paths
  has_many :items, through: :item_paths
end
