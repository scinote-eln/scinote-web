# frozen_string_literal: true

module Reports::Docx::DrawMyModuleProtocol
  def draw_my_module_protocol(my_module)
    protocol = my_module.protocol

    @docx.h4 protocol.name, italic: false

    if protocol.description.present?
      @docx.h4 protocol.name if my_module.results.any?
      @docx.p I18n.t 'projects.reports.elements.module.protocol.user_time',
                     timestamp: I18n.l(protocol.created_at, format: :full)
      @docx.hr
      html = custom_auto_link(protocol.description, team: @report_team)
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
      @docx.p
      @docx.p
    end
  end
end
