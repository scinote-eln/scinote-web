class RemoveDefaultChecklistItemPositionValue < ActiveRecord::Migration
  def up
    change_column :checklist_items,
                  :position,
                  :integer,
                  default: nil,
                  null: true
  end

  def down
    change_column :checklist_items,
                  :position,
                  :integer,
                  default: 0,
                  null: false
  end
end
