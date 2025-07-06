class SearchHistory < ApplicationRecord
  belongs_to :user, optional: true

  validates :query, presence: true
  validates :searched_at, presence: true
  validates :result_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { order(searched_at: :desc) }
  scope :for_user, ->(user) { where(user: user) }

  # Class method to record a search
  def self.record_search(user, query, result_count)
    # Only record non-empty searches
    return if query.blank?
    
    # Don't record duplicate searches within the last hour
    existing = where(user: user, query: query)
                .where('searched_at > ?', 1.hour.ago)
                .first
    
    if existing
      existing.update(searched_at: Time.current, result_count: result_count)
    else
      create!(
        user: user,
        query: query,
        result_count: result_count,
        searched_at: Time.current
      )
    end
  end

  # Get recent searches for a user
  def self.recent_for_user(user, limit = 10)
    for_user(user).recent.limit(limit)
  end
end