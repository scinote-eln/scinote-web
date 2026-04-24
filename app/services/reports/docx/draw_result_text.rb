# frozen_string_literal: true

module Reports::Docx::DrawResultText
  def draw_result_text(result_text)
    timestamp = result_text.created_at
    settings = @settings
    color = @color
    if result_text.name.present? || !settings['exclude_timestamps']
      @docx.p do
        text result_text.name.to_s, italic: true
        text ' ' if result_text.name.present?
        text " | #{I18n.t('search.index.archived')} ", bold: true if result_text.archived?
        unless settings['exclude_timestamps']
          text '| ' if result_text.name.present?
          if result_text.archived?
            text I18n.t('projects.reports.elements.archived_metadata',
                        datetime: I18n.l(result_text.archived_on, format: :full),
                        user: result_text.archived_by&.full_name), color: color[:gray]
          else
            text I18n.t('projects.reports.elements.result_text.user_time',
                        timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
          end
        end
      end
    end
    html = custom_auto_link(result_text.text, team: @report_team)
    Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                              link_style: @link_style }).html_to_word_converter(html)
  end
end
