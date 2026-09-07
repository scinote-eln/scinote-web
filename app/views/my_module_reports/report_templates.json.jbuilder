# frozen_string_literal: true

json.templates do
  json.array! @report_templates.each do |report_template|
    json.id report_template.id
    json.name report_template.name
    json.generating_report @in_progress_template_ids.include?(report_template.id)
    json.preview preview_protocol_protocol_report_template_path(@my_module.protocol, report_template)
  end
end
