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

    LabelTemplate.reset_column_information

    # Remove our original default template
    LabelTemplate.order(created_at: :asc).find_by(default: true)&.destroy

    Team.find_each do |team|
      FluicsLabelTemplate.create!(
        name: I18n.t('label_templates.default_fluics_name'),
        width_mm: 25.4,
        height_mm: 12.7,
        content: Extends::DEFAULT_LABEL_TEMPLATE[:zpl],
        team: team,
        default: true
      )

      ZebraLabelTemplate.create!(
        name: I18n.t('label_templates.default_zebra_name'),
        width_mm: 25.4,
        height_mm: 12.7,
        content: Extends::DEFAULT_LABEL_TEMPLATE[:zpl],
        team: team,
        default: true
      )
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
