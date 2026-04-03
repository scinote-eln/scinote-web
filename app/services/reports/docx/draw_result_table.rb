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
      text " | #{I18n.t('search.index.archived')} ", bold: true if table.archived?
      unless settings['exclude_timestamps']
        text '| '
        if table.archived?
          text I18n.t('projects.reports.elements.archived_metadata',
                      datetime: I18n.l(table.result_table.result_orderable_element.archived_on, format: :full),
                      user: table.result_table.result_orderable_element.archived_by&.full_name), color: color[:gray]
        else
          text I18n.t('projects.reports.elements.result_table.user_time',
                      timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: color[:gray]
        end
      end
    end
  end
end
