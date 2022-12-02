# frozen_string_literal: true

module MyModules
  class CopyContentJob < ApplicationJob
    def perform(user, source_my_module_id, target_my_module_id)
      MyModule.transaction do
        target_my_module = MyModule.find(target_my_module_id)
        MyModule.find(source_my_module_id).copy_content(user, target_my_module)
        target_my_module.update!(provisioning_status: :done)
      end
    rescue StandardError => _e
      target_my_module.update(provisioning_status: :failed)
    end
  end
end
