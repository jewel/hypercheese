class Star < ActiveRecord::Base
  belongs_to :item
  belongs_to :user

  after_save do |star|
    UpdateActivityJob.perform_later
  end

  after_destroy do |star|
    UpdateActivityJob.perform_later
  end
end
