class Star < ActiveRecord::Base
  belongs_to :item
  belongs_to :user

  after_save do |comment|
    UpdateActivityJob.perform_later
  end
end
