class Log < ActiveRecord::Base
  validates :message, presence: true
  validates :team, presence: true

  belongs_to :team, inverse_of: :logs
end
