# frozen_string_literal: true

class UpdateCellLinesRepositoryTemplates < ActiveRecord::Migration[7.2]
  def up
    RepositoryTemplate.where(predefined: true, name: I18n.t('repository_templates.cell_lines_template_name')).find_each do |repository_template|
      repository_template.update!(column_definitions: RepositoryTemplate.cell_lines.column_definitions)
    end
  end
end
