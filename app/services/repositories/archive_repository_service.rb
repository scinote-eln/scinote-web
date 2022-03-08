# frozen_string_literal: true

module Repositories
  class ArchiveRepositoryService < ArchiveRepositoryBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repositories.each do |repository|
          repository.archive!(@user)

          log_activity(:archive_inventory, repository)
        end
<<<<<<< HEAD
      rescue ActiveRecord::RecordInvalid
=======
      rescue ActiveRecord::RecordNotSaved
>>>>>>> Pulled latest release
        @errors[:archiving_error] = I18n.t('repositories.archive_inventories.unsuccess_flash')
        raise ActiveRecord::Rollback
      end

      self
    end
  end
end
