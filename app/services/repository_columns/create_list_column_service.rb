# frozen_string_literal: true

module RepositoryColumns
  class CreateListColumnService < CreateColumnService
    def initialize(user, repository_id, name, list_items)
      super(user, repository_id, name)
      @list_items = list_items
    end

    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        create_base_column(Extends::REPOSITORY_DATA_TYPES[:RepositoryListValue])

        # TODO
      end

      self
    end

    private

    def valid?

    end
  end
end
