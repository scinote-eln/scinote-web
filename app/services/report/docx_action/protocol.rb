# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren

module Report::DocxAction::Protocol
  def draw_protocol(protocol)
    @docx.p I18n.t 'projects.reports.elements.module.protocol.user_time',
                   timestamp: I18n.l(protocol.created_at, format: :full)
    @docx.hr
    if protocol.description.present?
      html = SmartAnnotations::TagToHtml.new(@user, @report_team, protocol.description).html
      html_to_word_converter(html)
    else
      @docx.p I18n.t 'my_modules.protocols.protocol_status_bar.no_description'
    end
    @docx.p
    @docx.p
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
