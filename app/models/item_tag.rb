class ItemTag < ActiveRecord::Base
  belongs_to :item
  belongs_to :tag
end
