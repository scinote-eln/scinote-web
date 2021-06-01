# frozen_string_literal: true

module SettingsModel
  extend ActiveSupport::Concern

  included do
    serialize :settings, JsonbHashSerializer
    after_initialize :init_default_settings, if: :new_record?
  end

  protected

  def init_default_settings
    self.settings = self.class::DEFAULT_SETTINGS
  end
end
