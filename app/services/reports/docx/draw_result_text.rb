# frozen_string_literal: true

module Reports::Docx::DrawResultText
  def draw_result_text(element)
    result = element.result
    result_text = element.orderable
    color = @color
    @docx.p result_text.name.presence || '', italic: true
    html = custom_auto_link(result_text.text, team: @report_team)
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                              link_style: @link_style }).html_to_word_converter(html)

    draw_result_comments(result) if @settings.dig('task', 'result_comments')
  end
end
