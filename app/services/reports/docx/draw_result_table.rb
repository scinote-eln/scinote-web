# frozen_string_literal: true

module Reports::Docx::DrawResultTable
  def draw_result_table(element)
    result = element.result
    table = element.orderable.table
    timestamp = table.created_at
    settings = @settings
    color = @color
    obj = self
    table_type = table.metadata.dig('plateTemplate') ? 'well_plates_table' : 'table'
    obj.render_table(table, table_type, color)
    @docx.p do
      text I18n.t 'projects.reports.elements.result_table.table_name', name: table.name
      unless settings['exclude_timestamps']
        text ' '
        text I18n.t('projects.reports.elements.result_table.user_time',
                    timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: color[:gray]
      end
    end
  end
end
