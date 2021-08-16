# frozen_string_literal: true

module RepositoryActions
  class ArchiveRowsService < ArchiveRowsBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repository_rows.find_each(batch_size: 100) do |row|
          row.archive!(@user)
          log_activity(:archive_inventory_item, row) if @log_activities
        end
<<<<<<< HEAD
<<<<<<< HEAD
      rescue ActiveRecord::RecordInvalid
        @errors[:archiving_error] = I18n.t('repositories.archive_records.unsuccess_flash', repository: @repository.name)
=======
      rescue ActiveRecord::RecordNotSaved
        @errors[:archiving_error] = I18n.t('repositories.archive_records.unsuccess_flash', @repository.name)
>>>>>>> Pulled latest release
=======
      rescue ActiveRecord::RecordInvalid
        @errors[:archiving_error] = I18n.t('repositories.archive_records.unsuccess_flash', repository: @repository.name)
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
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
