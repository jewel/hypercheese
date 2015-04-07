class Share < ActiveRecord::Base
  has_many :items, through: :share_items
  has_many :share_items
  belongs_to :user
end
