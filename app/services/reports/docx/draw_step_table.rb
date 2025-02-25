# frozen_string_literal: true

module Reports::Docx::DrawStepTable
  def draw_step_table(table, table_type)
    color = @color
    timestamp = table.created_at
    settings = @settings
    obj = self
    obj.render_table(table, table_type, color)

    i18n_string = if table_type == 'step_table'
                    'projects.reports.elements.step_table'
                  elsif table_type == 'well_plates_table'
                    'projects.reports.elements.step_well_plates_table'
                  end


    @docx.p do
      text I18n.t("#{i18n_string}.table_name", name: table.name), italic: true
      unless settings['exclude_timestamps']
        text ' '
        text I18n.t("#{i18n_string}.user_time",
                    timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
      end
    end
  end
end
