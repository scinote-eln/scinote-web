# frozen_string_literal: true

module RepositoryActions
  class RestoreRowsService < ArchiveRowsBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repository_rows.each do |row|
          row.restore!(@user)
          log_activity(:restore_inventory_item, row)
        end
      rescue ActiveRecord::RecordNotSaved
        @errors[:restoring_error] = 'Cannot restore all items'
        raise ActiveRecord::Rollback
      end

      self
    end

    private

    def scoped_repository_rows(ids)
      @repository.repository_rows.where(id: ids).archived
    end
  end
end
