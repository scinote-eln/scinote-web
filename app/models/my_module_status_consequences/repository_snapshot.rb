# frozen_string_literal: true

module MyModuleStatusConsequences
  class RepositorySnapshot < MyModuleStatusConsequence
    def runs_in_background?
      true
    end

    def before_forward_call(my_module, created_by = nil)
      my_module.assigned_repositories.each do |repository|
        ::RepositorySnapshot.create_preliminary!(repository, my_module, created_by)
      end
    end

    def forward(my_module)
      my_module.repository_snapshots.where(status: :provisioning).find_each do |repository_snapshot|
        service = Repositories::SnapshotProvisioningService.call(repository_snapshot: repository_snapshot)

        unless service.succeed?
          raise MyModuleStatus::MyModuleStatusTransitionError.new(
            {
              type: :repository_snapshot,
              repository_id: repository_snapshot.parent_id,
              repository_snapshot_id: repository_snapshot.id,
              message: service.errors.values.join("\n")
            }
          )
        end

        snapshot = service.repository_snapshot
        unless snapshot.my_module.repository_snapshots.where(parent_id: snapshot.parent_id).find_by(selected: true)
          snapshot.update!(selected: true)
        end
      end
    end
  end
end
