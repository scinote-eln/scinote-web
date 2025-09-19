# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActiveStorage::Blob::Analyzable.module_eval do
    alias_method :original_analyze, :analyze

    def analyze
      ActiveRecord::Base.no_touching do
        original_analyze
      end
    end
  end
end
