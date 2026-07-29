# frozen_string_literal: true

class AddGenerationAttributeToReportTemplates < ActiveRecord::Migration[7.2]
  def change
    add_column :report_templates, :generating_report, :boolean, default: false, null: false
  end
end
