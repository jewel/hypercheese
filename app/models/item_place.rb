class ItemPlace < ActiveRecord::Base
  belongs_to :item
  belongs_to :place
  belongs_to :user, optional: true

  validates :item_id, uniqueness: { scope: :place_id }
  
  # Check if this association was added by the system
  def system_added?
    user_id.nil?
  end

  # Check if this association was added by a user
  def user_added?
    user_id.present?
  end
end