class AddPositionToChecklistItem < ActiveRecord::Migration[4.2]
  def change
    add_column :checklist_items, :position, :integer, { default: 0, null: false }

    Checklist.transaction do
      Checklist.all.each do |checklist|
        pos = 0

        checklist.checklist_items.each do |item|
          item.position = pos
          pos += 1
        end

        checklist.save!
      end
    end
  end
end
