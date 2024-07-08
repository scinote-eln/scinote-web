# frozen_string_literal: true

module SettingsModel
  extend ActiveSupport::Concern

  included do
    serialize :settings, JsonbHashSerializer
    after_initialize :init_default_settings, if: :new_record?
  end

  def update_simple_setting(key:, value:)
    raise ArgumentError, 'Unauthorized setting key' unless Extends::WHITELISTED_USER_SETTINGS.include?(key.to_s)

    settings[key] = value
    save
  end

  def update_nested_setting(key:, id:, value:)
    raise ArgumentError, 'Unauthorized setting key' unless Extends::WHITELISTED_USER_SETTINGS.include?(key.to_s)

    settings[key] ||= {}
    settings[key][id.to_s] = value
    save
  end

  protected

  def init_default_settings
    self.settings = self.class::DEFAULT_SETTINGS
  end
end
