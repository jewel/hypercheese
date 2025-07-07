class ItemPlace < ActiveRecord::Base
  belongs_to :item
  belongs_to :place
  belongs_to :user, optional: true

  validates :item_id, uniqueness: { scope: :place_id }

  def system_added?
    user_id.nil?
  end

  def user_added?
    user_id.present?
  end
end
