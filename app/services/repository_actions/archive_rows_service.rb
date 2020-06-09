# frozen_string_literal: true

module RepositoryActions
  class ArchiveRowsService < ArchiveRowsBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repository_rows.each do |row|
          row.archive!(@user)
          log_activity(:archive_inventory_item, row)
        end
      rescue ActiveRecord::RecordNotSaved
        @errors[:archiving_error] = 'Cannot archive all items'
        raise ActiveRecord::Rollback
      end

      self
    end

    private

    def scoped_repository_rows(ids)
      @repository.repository_rows.where(id: ids).active
    end
  end
end
