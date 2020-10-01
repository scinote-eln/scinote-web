# frozen_string_literal: true

class MigrateTaskStatus < ActiveRecord::Migration[6.0]
  def up
    MyModuleStatusFlow.ensure_default

    in_progress_status = execute("SELECT id FROM my_module_statuses WHERE name = 'In progress' LIMIT 1").to_a[0]
    completed_status = execute("SELECT id FROM my_module_statuses WHERE name = 'Completed' LIMIT 1").to_a[0]

    if in_progress_status
      execute("UPDATE my_modules
               SET my_module_status_id = #{in_progress_status['id']} WHERE state = 0")
    end

    if completed_status
      execute("UPDATE my_modules
               SET my_module_status_id = #{completed_status['id']} WHERE state = 1")
    end
  end
end
