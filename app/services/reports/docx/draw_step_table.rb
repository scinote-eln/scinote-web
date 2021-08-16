# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawStepTable
<<<<<<< HEAD
<<<<<<< HEAD
  def draw_step_table(table)
=======
module DrawStepTable
=======
module Reports::Docx::DrawStepTable
>>>>>>> Initial commit of 1.17.2 merge
  def draw_step_table(subject)
    table = Table.find_by_id(subject['id']['table_id'])
=======
  def draw_step_table(subject, step)
    table = step.tables.find_by(id: subject['id']['table_id'])
>>>>>>> Pulled latest release
    return unless table

>>>>>>> Finished merging. Test on dev machine (iMac).
=======
  def draw_step_table(table)
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    color = @color
    timestamp = table.created_at
    @docx.p
    @docx.p do
      text I18n.t('projects.reports.elements.step_table.table_name', name: table.name), italic: true
      text ' '
      text I18n.t('projects.reports.elements.step_table.user_time',
                  timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
    end
    @docx.table JSON.parse(table.contents_utf_8)['data'], border_size: Constants::REPORT_DOCX_TABLE_BORDER_SIZE
  end
end
