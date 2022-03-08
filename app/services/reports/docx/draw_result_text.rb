# frozen_string_literal: true

module Reports::Docx::DrawResultText
  def draw_result_text(result)
    result_text = result.result_text
    timestamp = result.created_at
    color = @color
    @docx.p
    @docx.p do
      text result.name, italic: true
      text ' ' + I18n.t('search.index.archived'), color: color[:gray] if result.archived?
      text ' '
      text I18n.t('projects.reports.elements.result_table.user_time',
                  timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: color[:gray]
    end
    html = custom_auto_link(result_text.text, team: @report_team)
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                              link_style: @link_style }).html_to_word_converter(html)

    draw_result_comments(result) if @settings.dig('task', 'result_comments')
  end
end
