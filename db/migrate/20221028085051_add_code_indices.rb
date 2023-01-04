# frozen_string_literal: true

class AddCodeIndices < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_projects_on_project_code ON "\
      "projects using gin (('#{Project::ID_PREFIX}'::text || id) gin_trgm_ops);"
    )
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_my_modules_on_my_module_code ON "\
      "my_modules using gin (('#{MyModule::ID_PREFIX}'::text || id) gin_trgm_ops);"
    )
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_protocols_on_protocol_code ON "\
      "protocols using gin (('#{Protocol::ID_PREFIX}'::text || id) gin_trgm_ops);"
    )
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_reports_on_report_code ON "\
      "reports using gin (('#{Report::ID_PREFIX}'::text || id) gin_trgm_ops);"
    )
  end

  def down
    remove_index :projects, name: 'index_projects_on_project_code'
    remove_index :my_modules, name: 'index_my_modules_on_my_module_code'
    remove_index :protocols, name: 'index_protocols_on_protocol_code'
    remove_index :reports, name: 'index_reports_on_report_code'
  end
end
