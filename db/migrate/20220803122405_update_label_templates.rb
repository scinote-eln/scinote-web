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
  end

  def down
    change_table :label_templates, bulk: true do |t|
      t.remove :type
      t.remove :width_mm
      t.remove :height_mm
      t.string :format, null: false, default: 'ZPL'
      t.integer :language_type
      t.string :size
    end
  end
end
