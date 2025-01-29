# frozen_string_literal: true

class AddPredefinedToLabelTemplates < ActiveRecord::Migration[7.0]
  class LabelTemplate < ActiveRecord::Base; end

  def up
    add_column :label_templates, :predefined, :boolean, default: false, null: false

    # rubocop:disable Rails/SkipsModelValidations
    LabelTemplate.where(
      name: [
        I18n.t('label_templates.default_zebra_name'),
        I18n.t('label_templates.default_zebra_name_203dpi'),
        I18n.t('label_templates.default_fluics_name')
      ]
    ).update_all(predefined: true)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    remove_column :label_templates, :predefined
  end
end
