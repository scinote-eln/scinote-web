# frozen_string_literal: true

class AddWithParagraphsToChecklistItem < ActiveRecord::Migration[7.0]
  def change
    add_column :checklist_items, :with_paragraphs, :boolean, default: false

    ChecklistItem.where("text ~ '^.*\\n.*$'").update_all(with_paragraphs: true)
  end
end
