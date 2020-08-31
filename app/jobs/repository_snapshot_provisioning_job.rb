# frozen_string_literal: true

class RepositorySnapshotProvisioningJob < ApplicationJob
  queue_as :high_priority

  def perform(repository_snapshot)
    service = Repositories::SnapshotProvisioningService.call(repository_snapshot: repository_snapshot)

    repository_snapshot.failed! unless service.succeed?
  end
end
