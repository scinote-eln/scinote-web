# frozen_string_literal: true

module MetadataModel
  extend ActiveSupport::Concern

  included do
    scope :with_metadata_value, lambda { |key, value|
      # sanitize key, replace . with -> and replace last -> with ->> to ensure string comparison at last level
      db_key =
        "metadata->#{key.to_s.split('.').map { |k| "'#{k.parameterize(separator: '_')}'" }.join('->')}".sub(/->(?!.*->)/, '->>')
      where("#{db_key} = ?", value.to_s)
    }

    before_save :sanitize_metadata_keys!

    def sanitize_metadata_keys!
      return unless metadata

      self.metadata = metadata.deep_transform_keys { |k| k.parameterize(separator: '_') }
    end
  end
end
