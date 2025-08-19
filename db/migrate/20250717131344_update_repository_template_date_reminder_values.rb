# frozen_string_literal: true

class UpdateRepositoryTemplateDateReminderValues < ActiveRecord::Migration[7.2]
  def change
    return unless ENV['SCINOTE_REPOSITORY_TEMPLATES_ENABLED'] == 'true'

    RepositoryTemplate.where(name: I18n.t('repository_templates.equipment_template_name')).find_each do |repository_template|
      repository_template.update!(column_definitions: RepositoryTemplate.equipment.column_definitions)
    end

    RepositoryTemplate.where(name: I18n.t('repository_templates.chemicals_and_reagents_template_name')).find_each do |repository_template|
      repository_template.update!(column_definitions: RepositoryTemplate.equipment.column_definitions)
    end
  end
end
