# frozen_string_literal: true

class MigrateTaskStatus < ActiveRecord::Migration[6.0]
  def up
    in_progress_status = execute("SELECT id FROM my_module_statuses WHERE name = 'In progress' LIMIT 1")[0]&['id']
    completed_status = execute("SELECT id FROM my_module_statuses WHERE name = 'Completed' LIMIT 1")[0]&['id']

    execute "UPDATE my_modules SET my_module_status_id = #{in_progress_status} WHERE state = 0"
    execute "UPDATE my_modules SET my_module_status_id = #{completed_status} WHERE state = 1"
  end
end
