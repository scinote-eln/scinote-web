# frozen_string_literal: true

class AddLabelTemplateUnits < ActiveRecord::Migration[6.1]
  def up
    change_table :label_templates, bulk: true do |t|
      t.integer :unit, default: 0
      t.integer :density, default: 12
    end
  end

  def down
    change_table :label_templates, bulk: true do |t|
      t.remove :unit
      t.remove :density
    end
  end
end
