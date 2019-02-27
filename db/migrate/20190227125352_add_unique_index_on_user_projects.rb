# frozen_string_literal: true

class AddUniqueIndexOnUserProjects < ActiveRecord::Migration[5.1]
  def up
    # firstly delete the duplicates
    execute 'WITH uniq AS
      (SELECT DISTINCT ON (user_id, project_id) * FROM user_projects)
      DELETE FROM user_projects WHERE user_projects.id NOT IN
        (SELECT id FROM uniq)'
    add_index :user_projects, %i(user_id project_id), unique: true
  end

  def down
    remove_index :user_projects, columns: %i(user_id project_id)
  end
end
