class AddArchiveToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :archived, :boolean, { default: false, null: false }
    add_column :projects, :archived_on, :datetime
  end
end
