# frozen_string_literal: true

class Webhook < ApplicationRecord
  enum http_method: { get: 0, post: 1, patch: 2 }

  belongs_to :activity_filter
  validates :http_method, presence: true
  validates :url, presence: true
  validate :enabled?
  validate :valid_url

  scope :active, -> { where(active: true) }

  private

  def enabled?
    unless Rails.application.config.x.webhooks_enabled
      errors.add(:configuration, I18n.t('activerecord.errors.models.webhook.attributes.configuration.disabled'))
    end
  end

  def valid_url
    unless /\A#{URI::DEFAULT_PARSER.make_regexp(%w(http https))}\z/.match?(url)
      errors.add(:url, I18n.t('activerecord.errors.models.webhook.attributes.url.not_valid'))
    end
  end
end
