# frozen_string_literal: true

module MyModuleStatusConsequences
  class RepositorySnapshot < MyModuleStatusConsequence
    def runs_in_background?
      true
    end

    def call(my_module)
      my_module.assigned_repositories.each do |repository|
        repository_snapshot = ::RepositorySnapshot.create_preliminary(repository, my_module)
        service = Repositories::SnapshotProvisioningService.call(repository_snapshot: repository_snapshot)

        unless service.succeed?
          repository_snapshot.failed!
          raise StandardError, service.errors
        end

        snapshot = service.repository_snapshot
        unless snapshot.my_module.repository_snapshots.where(parent_id: snapshot.parent_id).find_by(selected: true)
          snapshot.update!(selected: true)
        end
      end
    end
  end
end
