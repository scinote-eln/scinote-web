# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::ResultTable
  def draw_result_table(result, children)
    table = result.table
    timestamp = table.created_at
    @docx.p
    @docx.p do
      text result.name
      text ' ' + I18n.t('search.index.archived'), color: 'a0a0a0' if result.archived?
      text ' '
      text I18n.t 'projects.reports.elements.result_table.table_name', name: table.name
      text ' '
      text I18n.t('projects.reports.elements.result_text.user_time',
                  timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: 'a0a0a0'
    end
    @docx.table JSON.parse(table.contents_utf_8)['data'], border_color: '666666'
    children.each do |result_hash|
      draw_result_comments(result, result_hash['sort_order']) if result_hash['type_of'] == 'result_comments'
    end
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
