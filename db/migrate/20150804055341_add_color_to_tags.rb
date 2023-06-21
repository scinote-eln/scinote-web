class AddColorToTags < ActiveRecord::Migration[4.2]
  def change
    add_column :tags, :color, :string, default: '#ff0000', null: false
  end
end
