# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawResultTable
<<<<<<< HEAD
<<<<<<< HEAD
  def draw_result_table(result)
=======
module DrawResultTable
=======
module Reports::Docx::DrawResultTable
>>>>>>> Initial commit of 1.17.2 merge
  def draw_result_table(subject)
    result = Result.find_by_id(subject['id']['result_id'])
=======
  def draw_result_table(subject, my_module)
    result = my_module.results.find_by(id: subject['id']['result_id'])
>>>>>>> Pulled latest release
    return unless result

>>>>>>> Finished merging. Test on dev machine (iMac).
=======
  def draw_result_table(result)
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    table = result.table
    timestamp = table.created_at
    color = @color
    @docx.p
    @docx.p do
      text result.name, italic: true
      text ' ' + I18n.t('search.index.archived'), color: color[:gray] if result.archived?
      text ' '
      text I18n.t 'projects.reports.elements.result_table.table_name', name: table.name
      text ' '
      text I18n.t('projects.reports.elements.result_text.user_time',
                  timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: color[:gray]
    end
    @docx.table JSON.parse(table.contents_utf_8)['data'], border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE
<<<<<<< HEAD
<<<<<<< HEAD

    draw_result_comments(result) if @settings.dig('task', 'result_comments')
=======
    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child, result)
    end
>>>>>>> Finished merging. Test on dev machine (iMac).
=======

    draw_result_comments(result) if @settings.dig('task', 'result_comments')
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
  end
end
