class ShareItem < ActiveRecord::Base
  belongs_to :share
  belongs_to :item
end
