# frozen_string_literal: true

unless Rails.application.config.eager_load
  Rails.application.config.to_prepare do
    Extends::STI_PRELOAD_CLASSES.each(&:constantize)
  end
end
