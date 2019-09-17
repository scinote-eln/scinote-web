# frozen_string_literal: true

module Reports::Docx::DrawStepComments
  def draw_step_comments(subject)
    step = Step.find_by_id(subject['id']['step_id'])
    return unless step

    comments = step.step_comments
    return if comments.count.zero?

    @docx.p
    @docx.p I18n.t('projects.reports.elements.step_comments.name', step: step.name),
            bold: true, size: Constants::REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE
    comments.each do |comment|
      comment_ts = comment.created_at
      @docx.p I18n.t('projects.reports.elements.step_comments.comment_prefix',
                     user: comment.user.full_name,
                     date: I18n.l(comment_ts, format: :full_date),
                     time: I18n.l(comment_ts, format: :time)), italic: true
      html = custom_auto_link(comment.message, team: @report_team)
      html_to_word_converter(html)
      @docx.p
    end
  end
end
