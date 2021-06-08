# frozen_string_literal: true

class Webhook < ApplicationRecord
  enum method: { get: 0, post: 1, patch: 2 }

  belongs_to :activity_filter
  validates :method, presence: true
  validates :url, presence: true
  validate :valid_url

  private

  def valid_url
    parsed_url = URI.parse(url)
    raise URI::InvalidURIError unless parsed_url.host
  rescue URI::InvalidURIError
    errors.add(:url, I18n.t('activerecord.errors.models.webhook.attributes.url.not_valid'))
  end
end
