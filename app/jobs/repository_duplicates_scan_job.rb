# frozen_string_literal: true

class RepositoryDuplicatesScanJob < ApplicationJob
  queue_as :default

  LOCK_NAME = 'repository_duplicates_scan'

  def self.schedule(repository_id)
    return unless RepositoryBase.inventory_integrity_enabled?

    perform_later(repository_id)
  end

  def perform(repository_id)
    repository = Repository.find_by(id: repository_id)
    return unless repository

    with_scan_lock(repository_id) do
      duplicate_ids = RepositoryRows::DuplicatesScanService.new(repository).call

      RepositoryBase.transaction do
        rows = RepositoryRow.where(repository_id: repository_id)
        rows.where(duplicated: true).where.not(id: duplicate_ids).update_all(duplicated: false)
        rows.where(id: duplicate_ids, duplicated: false).update_all(duplicated: true)
        repository.update_column(:duplicated_items_count, duplicate_ids.size)
      end
    end
  end

  private

  def with_scan_lock(repository_id)
    connection = ActiveRecord::Base.connection
    connection.select_value("SELECT pg_advisory_lock(hashtext('#{LOCK_NAME}'), #{repository_id.to_i})")
    yield
  ensure
    connection&.select_value("SELECT pg_advisory_unlock(hashtext('#{LOCK_NAME}'), #{repository_id.to_i})")
  end
end
