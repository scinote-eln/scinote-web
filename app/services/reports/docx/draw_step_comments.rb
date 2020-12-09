# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawStepComments
<<<<<<< HEAD
  def draw_step_comments(step)
    comments = step.step_comments.order(created_at: :desc)
    return if comments.blank?
=======
module DrawStepComments
=======
module Reports::Docx::DrawStepComments
>>>>>>> Initial commit of 1.17.2 merge
  def draw_step_comments(subject)
    step = Step.find_by_id(subject['id']['step_id'])
=======
  def draw_step_comments(_subject, step)
>>>>>>> Pulled latest release
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
<<<<<<< HEAD
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
=======
      html_to_word_converter(html)
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
>>>>>>> Pulled latest release
      @docx.p
    end
  end
end
