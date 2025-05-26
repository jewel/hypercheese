class CheeseBlob < ApplicationRecord
  belongs_to :user
  belongs_to :device

  validates :path, presence: true
  validates :sha256, presence: true
  validates :size, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :mtime, presence: true

  def download_to_temp
    temp_dir = Rails.root.join 'tmp', 'downloads'
    FileUtils.mkdir_p temp_dir
    dest_path = File.join temp_dir, sha256
    temp_path = "#{dest_path}.#$$.tmp"

    unless File.exist? temp_path
      s3_key = "storage/#{sha256}"
      Bucket.object(s3_key).download_file temp_path
      File.rename temp_path, dest_path
    end

    dest_path
  end
end
