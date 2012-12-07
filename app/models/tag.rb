# == Schema Information
#
# Table name: tags
#
#  id            :integer          not null, primary key
#  label         :string(255)
#  birthday      :datetime
#  item_count    :integer
#  icon_item_id  :integer
#  parent_tag_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Tag < ActiveRecord::Base
  belongs_to :icon, class_name: 'Item', foreign_key: "icon_item_id"
  has_many :items, counter_cache: "item_count"
end
