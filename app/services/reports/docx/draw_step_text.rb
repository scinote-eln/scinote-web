# frozen_string_literal: true

module Reports::Docx::DrawStepText
  def draw_step_text(element)
    step_text = element.orderable
    timestamp = element.created_at
    color = @color
    @docx.p do
      text step_text.name.presence || '', italic: true
      text ' '
      text I18n.t('projects.reports.elements.result_text.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end
    if step_text.text.present?
      html = custom_auto_link(step_text.text, team: @report_team)
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
    else
      @docx.p I18n.t 'projects.reports.elements.step.no_description'
    end
  end
end
