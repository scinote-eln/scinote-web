# frozen_string_literal: true

module Reports::Docx::DrawStepText
  def draw_step_text(step_text)
    @docx.p step_text.name.presence || '', italic: true
    if step_text.text.present?
      html = custom_auto_link(step_text.text, team: @report_team)
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
    else
      @docx.p I18n.t 'projects.reports.elements.step.no_description'
    end
  end
end
