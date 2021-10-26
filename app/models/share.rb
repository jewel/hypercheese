class Share < ActiveRecord::Base
  has_many :share_items
  has_many :items, -> { where( deleted: false ) }, through: :share_items
  belongs_to :user
end
