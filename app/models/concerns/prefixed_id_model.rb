# frozen_string_literal: true

module PrefixedIdModel
  extend ActiveSupport::Concern

  included do
    indexdef = "CREATE INDEX index_#{name.underscore.pluralize}_on_#{name.underscore}_code"\
    " ON public.#{name.underscore.pluralize} USING gin ((('#{self::ID_PREFIX}'::text || id)) gin_trgm_ops)"

    index_exists = ActiveRecord::Base.connection.execute(
      "SELECT indexdef FROM pg_indexes WHERE tablename NOT LIKE 'pg%';"
    ).to_a.map(&:values).flatten.include?(indexdef)

    # rubocop:disable Rails/Output
    puts("\nWARNING missing index\n#{indexdef}\nfor prefixed id model #{name}!\n\n") unless index_exists
    # rubocop:enable Rails/Output

    self::PREFIXED_ID_SQL = "('#{self::ID_PREFIX}' || id)"

    def code
      "#{self.class::ID_PREFIX}#{id}"
    end
  end
end
