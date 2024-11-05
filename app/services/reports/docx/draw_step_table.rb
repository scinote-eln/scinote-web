# frozen_string_literal: true

module Reports::Docx::DrawStepTable
  def draw_step_table(table, table_type)
    color = @color
    timestamp = table.created_at
    obj = self
    obj.render_table(table, table_type, color)
    @docx.p do
      text I18n.t("projects.reports.elements.#{table_type}.table_name", name: table.name), italic: true
      text ' '
      text I18n.t("projects.reports.elements.#{table_type}.user_time",
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end
  end
end
