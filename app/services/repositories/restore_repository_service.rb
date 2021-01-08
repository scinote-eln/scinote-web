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
      rescue ActiveRecord::RecordInvalid
        @errors[:restoring_error] = I18n.t('repositories.restore_inventories.unsuccess_flash')
        raise ActiveRecord::Rollback
      end

      self
    end
  end
end
