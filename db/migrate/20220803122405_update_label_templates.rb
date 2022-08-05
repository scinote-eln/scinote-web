# frozen_string_literal: true

class UpdateLabelTemplates < ActiveRecord::Migration[6.1]
  def up
    change_table :label_templates, bulk: true do |t|
      t.string :type
      t.float :width_mm
      t.float :height_mm
      t.remove :format
      t.remove :language_type
      t.remove :size
    end

    # Remove our original default template
    LabelTemplate.order(created_at: :asc).where(default: true).first&.destroy

    Team.find_each { |t| t.__send__(:create_default_label_templates) }
  end

  def down
    change_table :label_templates, bulk: true do |t|
      t.remove :type
      t.remove :width_mm
      t.remoe :height_mm
      t.string :format, null: false, default: 'ZPL'
      t.integer :language_type
      t.string :size
    end
  end
end
