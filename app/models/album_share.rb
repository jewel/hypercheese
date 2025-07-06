class AlbumShare < ActiveRecord::Base
  belongs_to :album
  
  validates :code, presence: true, uniqueness: true
  
  before_create :generate_code
  
  private
  
  def generate_code
    self.code = SecureRandom.urlsafe_base64(8) if code.blank?
  end
end