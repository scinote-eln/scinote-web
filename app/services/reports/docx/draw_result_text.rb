# frozen_string_literal: true

module Reports::Docx::DrawResultText
  def draw_result_text(element)
    result_text = element.orderable
    timestamp = element.created_at
    color = @color
    @docx.p do
      text result_text.name.presence || '', italic: true
      text ' '
      text I18n.t('projects.reports.elements.result_text.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end
    html = custom_auto_link(result_text.text, team: @report_team)
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                              link_style: @link_style }).html_to_word_converter(html)
  end
end
