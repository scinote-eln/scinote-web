# frozen_string_literal: true

<<<<<<< HEAD
module Reports::Docx::DrawMyModuleProtocol
  def draw_my_module_protocol(my_module)
    protocol = my_module.protocol
    return false if protocol.description.blank?
=======
module DrawMyModuleProtocol
  def draw_my_module_protocol(subject)
    my_module = MyModule.find_by_id(subject['id']['my_module_id'])
    return unless my_module

    protocol = my_module.protocol
    return false unless protocol.description.present?
>>>>>>> Finished merging. Test on dev machine (iMac).

    @docx.p I18n.t 'projects.reports.elements.module.protocol.user_time',
                   timestamp: I18n.l(protocol.created_at, format: :full)
    @docx.hr
    html = custom_auto_link(protocol.description, team: @report_team)
<<<<<<< HEAD
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                              link_style: @link_style }).html_to_word_converter(html)
=======
    html_to_word_converter(html)
>>>>>>> Finished merging. Test on dev machine (iMac).
    @docx.p
    @docx.p
  end
end
