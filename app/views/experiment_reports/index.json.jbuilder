# frozen_string_literal: true

json.reports do
  json.array! @analytical_reports.each do |analytical_report|
    json.id analytical_report.id
    json.name analytical_report.name
    json.created_at I18n.l(analytical_report.created_at, format: :full)
    json.created_by analytical_report.created_by&.full_name
    json.preview preview_experiment_experiment_report_path(@experiment, analytical_report)
    json.file_size number_to_human_size(analytical_report.report.byte_size)
  end
end
