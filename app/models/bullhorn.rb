class Bullhorn < ActiveRecord::Base
  belongs_to :item
  belongs_to :user

  after_save do |bullhorn|
    UpdateActivityJob.perform_later
  end

  after_destroy do |bullhorn|
    UpdateActivityJob.perform_later
  end
end
