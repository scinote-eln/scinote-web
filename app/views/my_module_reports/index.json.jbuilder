# frozen_string_literal: true

json.reports do
  json.array! @analytical_reports.each do |analytical_report|
    json.id analytical_report.id
    json.name analytical_report.name
    json.created_at I18n.l(analytical_report.created_at, format: :full)
    json.preview preview_my_module_my_module_report_path(@my_module, analytical_report)
  end
end
