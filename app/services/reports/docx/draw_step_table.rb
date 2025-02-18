# frozen_string_literal: true

module Reports::Docx::DrawStepTable
  def draw_step_table(table, table_type)
    color = @color
    timestamp = table.created_at
    settings = @settings
    obj = self
    obj.render_table(table, table_type, color)
    @docx.p do
      text I18n.t("projects.reports.elements.step_#{table_type}.table_name", name: table.name), italic: true
      unless settings['exclude_timestamps']
        text ' '
        text I18n.t("projects.reports.elements.step_#{table_type}.user_time",
                    timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
      end
    end
  end
end
