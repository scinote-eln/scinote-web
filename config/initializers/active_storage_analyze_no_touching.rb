# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActiveStorage::AnalyzeJob.class_eval do
    alias_method :original_perform, :perform

    def perform(blob)
      ActiveRecord::Base.no_touching do
        original_perform(blob)
      end
    end
  end
end
