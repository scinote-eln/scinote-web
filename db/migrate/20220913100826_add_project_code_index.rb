class AddProjectCodeIndex < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.connection.execute(
      "CREATE INDEX index_projects_on_project_code ON "\
      "projects using gin (('PR'::text || id) gin_trgm_ops);"
    )
  end

  def down
    remove_index :projects, name: 'index_projects_on_project_code'
  end
end
