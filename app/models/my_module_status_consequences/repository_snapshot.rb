# frozen_string_literal: true

module MyModuleStatusConsequences
  class RepositorySnapshot < MyModuleStatusConsequence
    def runs_in_background?
      true
    end

    def before_forward_call(my_module, created_by = nil)
      my_module.assigned_repositories.each do |repository|
        ActiveRecord::Base.transaction do
          repository_snapshot = ::RepositorySnapshot.create_preliminary!(repository, my_module, created_by)

          if created_by
            Activities::CreateActivityService.call(
              activity_type: :repository_snapshot_created,
              owner: created_by,
              subject: my_module,
              team: my_module.team,
              message_items: {
                my_module: my_module.id,
                timestamp: repository_snapshot.created_at,
                repository: repository_snapshot.parent_id
              }
            )
          end
        end
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
