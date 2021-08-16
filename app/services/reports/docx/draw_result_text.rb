# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawResultText
<<<<<<< HEAD
<<<<<<< HEAD
  def draw_result_text(result)
=======
module DrawResultText
=======
module Reports::Docx::DrawResultText
>>>>>>> Initial commit of 1.17.2 merge
  def draw_result_text(subject)
    result = Result.find_by_id(subject['id']['result_id'])
=======
  def draw_result_text(subject, my_module)
    result = my_module.results.find_by(id: subject['id']['result_id'])
>>>>>>> Pulled latest release
    return unless result

>>>>>>> Finished merging. Test on dev machine (iMac).
=======
  def draw_result_text(result)
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
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
<<<<<<< HEAD
<<<<<<< HEAD
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                              link_style: @link_style }).html_to_word_converter(html)

    draw_result_comments(result) if @settings.dig('task', 'result_comments')
=======
    html_to_word_converter(html)
=======
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                              link_style: @link_style }).html_to_word_converter(html)
>>>>>>> Pulled latest release

<<<<<<< HEAD
    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child, result)
    end
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    draw_result_comments(result) if @settings.dig('task', 'result_comments')
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
  end
end
