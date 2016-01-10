class Tag < ActiveRecord::Base
  belongs_to :icon, class_name: 'Item', foreign_key: "icon_item_id"
  has_many :item_tags
  has_many :items, through: :item_tags
end
