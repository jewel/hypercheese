class Tag < ActiveRecord::Base
  belongs_to :icon, class_name: 'Item', foreign_key: "icon_item_id"
  has_many :item_tags
  has_many :items, through: :item_tags
  has_many :tag_aliases
  has_many :faces

  def parent
    return nil unless self.parent_tag_id
    Tag.find self.parent_tag_id rescue nil
  end
end
