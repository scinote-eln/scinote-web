# frozen_string_literal: true

module Reports::Docx::DrawStepText
  def draw_step_text(step_text)
    timestamp = element.created_at
    color = @color
    settings = @settings

    if step_text.name.present? || !settings['exclude_timestamps']
      @docx.p do
        text step_text.name.to_s, italic: true
        text ' ' if step_text.name.present?
        text " | #{I18n.t('search.index.archived')} ", bold: true if step_text.archived?
        unless settings['exclude_timestamps']
          text '| ' if step_text.name.present?
          if step_text.archived?
            text I18n.t('projects.reports.elements.archived_metadata',
                        datetime: I18n.l(step_text.archived_on, format: :full),
                        user: step_text.archived_by&.full_name), color: color[:gray]
          else
            text I18n.t('projects.reports.elements.result_text.user_time',
                        timestamp: I18n.l(timestamp, format: :full)), color: color[:gray]
          end
        end
      end
    end
    if step_text.text.present?
      html = custom_auto_link(step_text.text, team: @report_team)
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
    else
      @docx.p I18n.t 'projects.reports.elements.step.no_description'
    end
  end
end
