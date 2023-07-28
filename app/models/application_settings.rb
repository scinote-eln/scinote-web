# frozen_string_literal: true

class ApplicationSettings < Settings
  def load_values_from_env
    ENV.select { |name, _| name =~ /^APP_STTG_[A-Z0-9_]*/ }.transform_keys(&:downcase)
  end
end
