# frozen_string_literal: true

module Repositories
  class RestoreRepositoryService < ArchiveRepositoryBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repositories.each do |repository|
          repository.restore!(@user)

          log_activity(:restore_inventory, repository)
        end
<<<<<<< HEAD
<<<<<<< HEAD
      rescue ActiveRecord::RecordInvalid
=======
      rescue ActiveRecord::RecordNotSaved
>>>>>>> Pulled latest release
=======
      rescue ActiveRecord::RecordInvalid
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
        @errors[:restoring_error] = I18n.t('repositories.restore_inventories.unsuccess_flash')
        raise ActiveRecord::Rollback
      end

      self
    end
  end
end
