class CreateWidgets < ActiveRecord::Migration
  def change
    create_table :widgets do |t|
      t.integer :type
      t.integer :position
      t.text :properties
    end
  end
end
