# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawResultComments
  def draw_result_comments(result)
    comments = result.result_comments.order(created_at: :desc)
    return if comments.blank?
=======
module DrawResultComments
=======
module Reports::Docx::DrawResultComments
>>>>>>> Initial commit of 1.17.2 merge
  def draw_result_comments(subject)
    result = Result.find_by_id(subject['id']['result_id'])
    return unless result

    comments = result.result_comments.order(created_at: subject['sort_order'])
    return if comments.count.zero?
>>>>>>> Finished merging. Test on dev machine (iMac).

    @docx.p
    @docx.p I18n.t('projects.reports.elements.result_comments.name', result: result.name),
            bold: true, size: Constants::REPORT_DOCX_STEP_ELEMENTS_TITLE_SIZE
    comments.each do |comment|
      comment_ts = comment.created_at
      @docx.p I18n.t('projects.reports.elements.result_comments.comment_prefix',
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
