# frozen_string_literal: true

json.reports do
  json.array! @analytical_reports.each do |analytical_report|
    json.id analytical_report.id
    json.name analytical_report.name
    json.created_at I18n.l(analytical_report.created_at, format: :full)
  end
end
