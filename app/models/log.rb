class Log < ActiveRecord::Base
  validates :message, presence: true
  validates :organization, presence: true

  belongs_to :organization, inverse_of: :logs
end
