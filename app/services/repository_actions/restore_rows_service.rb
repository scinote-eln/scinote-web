# frozen_string_literal: true

module RepositoryActions
  class RestoreRowsService < ArchiveRowsBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repository_rows.find_each(batch_size: 100) do |row|
          row.restore!(@user)
          log_activity(:restore_inventory_item, row) if @log_activities
        end
      rescue ActiveRecord::RecordInvalid
        @errors[:restoring_error] = I18n.t('repositories.restore_records.unsuccess_flash', repository: @repository.name)
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
