class Device < ApplicationRecord
  has_many :cheese_blobs, dependent: :destroy
end
