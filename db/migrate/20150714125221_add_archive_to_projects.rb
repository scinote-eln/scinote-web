class AddArchiveToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :archived, :boolean, { default: false, null: false }
    add_column :projects, :archived_on, :datetime
  end
end
