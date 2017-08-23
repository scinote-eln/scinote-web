module SettingsModel
  extend ActiveSupport::Concern

  @@default_settings = HashWithIndifferentAccess.new

  included do
    serialize :settings, JsonbHashSerializer
    after_initialize :init_default_settings, if: :new_record?
  end

  class_methods do
    def default_settings(dfs)
      @@default_settings.merge!(dfs)
    end
  end

  protected

  def init_default_settings
    self.settings = @@default_settings
  end
end
