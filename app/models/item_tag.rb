class ItemTag < ActiveRecord::Base
  belongs_to :item
  belongs_to :tag
  belongs_to :user, foreign_key: 'added_by'
end
