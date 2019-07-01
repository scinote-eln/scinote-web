# frozen_string_literal: true

module DrawResultText
  def draw_result_text(subject)
    result = Result.find_by_id(subject['id']['result_id'])
    return unless result

    result_text = result.result_text
    timestamp = result.created_at
    @docx.p
    @docx.p do
      text result.name
      text ' ' + I18n.t('search.index.archived'), color: 'a0a0a0' if result.archived?
      text ' '
      text I18n.t('projects.reports.elements.result_table.user_time',
                  timestamp: I18n.l(timestamp, format: :full), user: result.user.full_name), color: 'a0a0a0'
    end
    html = custom_auto_link(result_text.text, team: @report_team)
    html_to_word_converter(html)

    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
    end
  end
end
