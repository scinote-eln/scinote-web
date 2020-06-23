# frozen_string_literal: true

module Repositories
  class RestoreRepositoryService < ArchiveRepositoryBaseService
    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repositories.each do |repository|
          repository.restore!(@user)

          # rubocop:disable Rails/SkipsModelValidations
          repository.repository_rows.archived.update_all(restored_on: repository.restored_on,
                                                         restored_by_id: repository.restored_by_id,
                                                         archived: false)
          # rubocop:enable Rails/SkipsModelValidations

          log_activity(:restore_inventory, repository)
        end
      rescue ActiveRecord::RecordNotSaved
        @errors[:restoring_error] = I18n.t('repositories.restore_inventories.unsuccess_flash')
        raise ActiveRecord::Rollback
      end

      self
    end

    private

    def scoped_repositories(ids)
      Repository.where(id: ids, team_id: @team)
    end
  end
end
