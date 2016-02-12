class AddArchiveToResults < ActiveRecord::Migration
  def change
    add_column :results, :archived, :boolean, { default: false, null: false }
    add_column :results, :archived_on, :datetime
  end
end
