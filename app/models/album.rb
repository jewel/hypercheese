class Album < ActiveRecord::Base
  belongs_to :user
  has_many :album_items, dependent: :destroy
  has_many :items, through: :album_items
  has_many :album_shares, dependent: :destroy
  
  validates :name, presence: true
  
  scope :ordered, -> { order(:name) }
  scope :recently_updated, -> { joins(:album_items).group('albums.id').order('MAX(album_items.created_at) DESC') }
  
  def items_ordered
    items.order(:taken, :id)
  end
  
  def last_updated_at
    album_items.maximum(:created_at) || created_at
  end
end