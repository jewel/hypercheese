class VideoSpeedSegment < ApplicationRecord
  belongs_to :item
  
  validates :start_time, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :end_time, presence: true, numericality: { greater_than: :start_time }
  validates :playback_rate, presence: true, numericality: { greater_than: 0 }
  validates :item_id, presence: true
  
  scope :ordered, -> { order(:start_time) }
  scope :for_time, ->(time) { where('start_time <= ? AND end_time > ?', time, time) }
  
  # Find the appropriate playback rate for a given time
  def self.playback_rate_at(time)
    segment = for_time(time).first
    segment&.playback_rate || 1.0
  end
  
  # Get all segments as a JSON array for JavaScript consumption
  def self.as_json_segments
    ordered.map do |segment|
      {
        start_time: segment.start_time,
        end_time: segment.end_time,
        playback_rate: segment.playback_rate,
        source_type: segment.source_type
      }
    end
  end
  
  # Duration of this segment in seconds
  def duration
    end_time - start_time
  end
  
  # Check if this segment overlaps with another time range
  def overlaps_with?(other_start, other_end)
    start_time < other_end && end_time > other_start
  end
end