# frozen_string_literal: true

module Repositories
  class RestoreRepositoryService < ArchiveRepositoryBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repositories.each do |repository|
          repository.restore!(@user)

          RepositoryActions::RestoreRowsService.call(repository: repository,
                                                     repository_rows: repository.repository_rows.pluck(:id),
                                                     user: @user,
                                                     team: @team,
                                                     log_activities: false)

          log_activity(:restore_inventory, repository)
        end
      rescue ActiveRecord::RecordNotSaved
        @errors[:restoring_error] = I18n.t('repositories.restore_inventories.unsuccess_flash')
        raise ActiveRecord::Rollback
      end

      self
    end
  end
end
