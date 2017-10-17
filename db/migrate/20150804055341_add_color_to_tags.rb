class AddColorToTags < ActiveRecord::Migration
  def change
    add_column :tags, :color, :string, { default: "#ff0000", null: false }
  end
end
