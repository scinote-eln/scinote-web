class AddExperimentLevel < ActiveRecord::Migration[4.2]
  def up
    # Create experiments table
    create_table :experiments do |t|
      t.string :name, null: false
      t.text :description
      t.integer :project_id, null: false
      t.integer :created_by_id, null: false
      t.integer :last_modified_by_id, null: false
      t.boolean :archived, null: false, default: false
      t.integer :archived_by_id
      t.datetime :archived_on
      t.integer :restored_by_id
      t.datetime :restored_on

      t.timestamps null: false
    end
    add_foreign_key :experiments, :users, column: :created_by_id
    add_foreign_key :experiments, :users, column: :last_modified_by_id
    add_foreign_key :experiments, :users, column: :archived_by_id
    add_foreign_key :experiments, :users, column: :restored_by_id
    add_index :experiments, :name
    add_index :experiments, :project_id
    add_index :experiments, :created_by_id
    add_index :experiments, :last_modified_by_id
    add_index :experiments, :archived_by_id
    add_index :experiments, :restored_by_id

    add_column :my_modules, :experiment_id, :integer, default: 0
    add_column :my_module_groups, :experiment_id, :integer, default: 0

    # Iterate through all projects
    Project.find_each do |project|
      my_modules = MyModule.where('project_id = ?', project.id)
      my_module_groups = MyModuleGroup.where('project_id = ?', project.id)

      if my_modules.count > 0
        # Create an experiment
        owner = project.user_projects.where(role: 0).first.user
        exp = Experiment.create(
          name: 'Test experiment',
          project: project,
          created_by: owner,
          last_modified_by: owner
        )

        # Assign all modules onto new experiment
        my_modules.find_each do |mm|
          mm.update_column(:experiment_id, exp.id)
        end

        if my_module_groups.count > 0
          # Also assign all module groups onto new experiment
          my_module_groups.find_each do |mmg|
            mmg.update_column(:experiment_id, exp.id)
          end
        end
      end
    end

    change_column_null :my_modules, :experiment_id, false
    remove_column :my_modules, :project_id
    add_foreign_key :my_modules, :experiments, column: :experiment_id
    add_index :my_modules, :experiment_id

    change_column_null :my_module_groups, :experiment_id, false
    remove_column :my_module_groups, :project_id
    add_foreign_key :my_module_groups, :experiments, column: :experiment_id
    add_index :my_module_groups, :experiment_id
  end

  def down
    add_column :my_modules, :project_id, :integer, default: 0
    add_column :my_module_groups, :project_id, :integer, default: 0

    # Update reference to projects from modules
    MyModule.find_each do |mm|
      exp = Experiment.where('id = ?', mm[:experiment_id]).take
      project = Project.where('id = ?', exp[:project_id]).take
      mm.update_column(:project_id, project.id)
    end

    # Update reference to projects from module groups
    MyModuleGroup.find_each do |mmg|
      exp = Experiment.where('id = ?', mmg[:experiment_id]).take
      project = Project.where('id = ?', exp[:project_id]).take
      mmg.update_column(:project_id, project.id)
    end

    change_column_null :my_modules, :project_id, false
    remove_index :my_modules, column: :experiment_id
    remove_foreign_key :my_modules, column: :experiment_id
    remove_column :my_modules, :experiment_id
    change_column_null :my_module_groups, :project_id, false
    remove_index :my_module_groups, column: :experiment_id
    remove_foreign_key :my_module_groups, column: :experiment_id
    remove_column :my_module_groups, :experiment_id

    # Drop experiments table
    remove_index :experiments, column: :name
    remove_index :experiments, column: :project_id
    remove_index :experiments, column: :created_by_id
    remove_index :experiments, column: :last_modified_by_id
    remove_index :experiments, column: :archived_by_id
    remove_index :experiments, column: :restored_by_id
    remove_foreign_key :experiments, column: :created_by_id
    remove_foreign_key :experiments, column: :last_modified_by_id
    remove_foreign_key :experiments, column: :archived_by_id
    remove_foreign_key :experiments, column: :restored_by_id
    drop_table :experiments
  end
end
