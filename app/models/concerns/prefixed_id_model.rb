# frozen_string_literal: true

module PrefixedIdModel
  extend ActiveSupport::Concern

  included do
    unless Rails.env.production?
      begin
        indexdef = "CREATE INDEX index_#{table_name}_on_#{name.underscore}_code " \
                   "ON public.#{table_name} USING gin ((('#{self::ID_PREFIX}'::text || id)) gin_trgm_ops)"

        index_exists = ActiveRecord::Base.connection.execute(
          "SELECT indexdef FROM pg_indexes WHERE tablename NOT LIKE 'pg%';"
        ).to_a.map(&:values).flatten.include?(indexdef)

        # rubocop:disable Rails/Output
        puts("\nWARNING missing index\n#{indexdef}\nfor prefixed id model #{name}!\n\n") unless index_exists
        # rubocop:enable Rails/Output
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
        # only applicable during build and when setting up project
      end
    end

    self::PREFIXED_ID_SQL = "('#{self::ID_PREFIX}' || #{table_name}.id)".freeze

    def self.code(id)
      "#{self::ID_PREFIX}#{id}"
    end

    def code
      "#{self.class::ID_PREFIX}#{id}"
    end
  end
end
