# frozen_string_literal: true

module MyModules
  class CopyContentJob < ApplicationJob
    def perform(user_id, source_my_module_id, target_my_module_id)
      user = User.find(user_id)
      target_my_module = MyModule.find(target_my_module_id)
      MyModule.transaction do
        MyModule.find(source_my_module_id).copy_content(user, target_my_module)
        create_copy_my_module_activity(user, source_my_module_id, target_my_module_id)
        target_my_module.update!(provisioning_status: :done)
      end
    rescue StandardError => e
      Rails.logger.error e.message
      target_my_module.update(provisioning_status: :failed)
    end

    private

    def create_copy_my_module_activity(user, my_module_original_id, my_module_new_id)
      my_module_new = MyModule.find(my_module_new_id)
      Activities::CreateActivityService
        .call(activity_type: :clone_module,
              owner: user,
              team: my_module_new.experiment.project.team,
              project: my_module_new.experiment.project,
              subject: my_module_new,
              message_items: { my_module_original: my_module_original_id,
                               my_module_new: my_module_new.id })
    end
  end
end
