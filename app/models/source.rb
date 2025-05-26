class Source < ActiveRecord::Base
  has_many :item_paths
  has_many :items, through: :item_paths
  belongs_to :user, optional: true
  belongs_to :device, optional: true
end
