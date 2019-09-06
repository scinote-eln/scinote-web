# frozen_string_literal: true

<<<<<<< HEAD
module Reports::Docx::DrawStepComments
  def draw_step_comments(step)
    comments = step.step_comments.order(created_at: :desc)
    return if comments.blank?
=======
module DrawStepComments
  def draw_step_comments(subject)
    step = Step.find_by_id(subject['id']['step_id'])
    return unless step

    comments = step.step_comments
    return if comments.count.zero?
>>>>>>> Finished merging. Test on dev machine (iMac).

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
<<<<<<< HEAD
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
=======
      html_to_word_converter(html)
>>>>>>> Finished merging. Test on dev machine (iMac).
      @docx.p
    end
  end
end
