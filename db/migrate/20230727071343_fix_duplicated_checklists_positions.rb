# frozen_string_literal: true

class FixDuplicatedChecklistsPositions < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.no_touching do
      checklists = Checklist.where(id: ChecklistItem.select(:checklist_id)
                                                    .group(:checklist_id, :position)
                                                    .having('COUNT(*) > 1').distinct)

      ChecklistItem.acts_as_list_no_update do
        checklists.find_each do |checklist|
          checklist.checklist_items.each.with_index do |checklist_item, index|
            checklist_item.position = index
            checklist_item.save!(validate: false)
          end
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
