# frozen_string_literal: true

class Add203DpiLabelTemplate < ActiveRecord::Migration[7.0]
  def up
    Team.find_each do |team|
      team.label_templates.find_by(type: 'ZebraLabelTemplate', name: 'SciNote Item (ZPL)')&.update(name: I18n.t('label_templates.default_zebra_name'))
      team.label_templates.create!(
        type: 'ZebraLabelTemplate',
        name: I18n.t('label_templates.default_zebra_name_203dpi'),
        default: false,
        content: Extends::DEFAULT_LABEL_TEMPLATE_203DPI[:zpl],
        width_mm: 25.4,
        height_mm: 12.7,
        unit: 'in',
        density: 12
      )
    end
  end

  def down
    Team.find_each do |team|
      team.label_templates.find_by(type: 'ZebraLabelTemplate', name: I18n.t('label_templates.default_zebra_name'))&.update(name: 'SciNote Item (ZPL)')
      team.label_templates.find_by(type: 'ZebraLabelTemplate', name: I18n.t('label_templates.default_zebra_name_203dpi'))&.destroy
    end
  end
end
