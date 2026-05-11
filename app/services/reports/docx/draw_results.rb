# frozen_string_literal: true

module Reports::Docx::DrawResults
  def draw_results(my_module, with_my_module_name: false)
    color = @color
    settings = @settings
    scinote_url = @scinote_url
    link_style = @link_style
    return unless can_read_my_module?(@user, my_module)

    results = @settings.dig('task', 'archived_results') ? my_module.results : my_module.results.active

    if results.any? && (%w(file_results table_results text_results).any? { |k| @settings.dig('task', k) })
      if with_my_module_name
        @docx.h3 do
          link  my_module.name,
                scinote_url + Rails.application.routes.url_helpers.protocols_my_module_path(my_module),
                link_style
        end
      end
      @docx.h4 I18n.t('Results')

      order_results_for_report(results, @settings.dig('task', 'result_order')).each do |result|
        @docx.p do
          text result.name.presence || I18n.t('projects.reports.unnamed'), italic: true
          text " | #{I18n.t('search.index.archived')} ", bold: true if result.archived?
          unless settings['exclude_timestamps']
            text '| '
            if result.archived?
              text I18n.t('projects.reports.elements.archived_metadata',
                          datetime: I18n.l(result.archived_on, format: :full),
                          user: result.archived_by&.full_name), color: color[:gray]
            else
              text I18n.t('projects.reports.elements.result.user_time',
                          timestamp: I18n.l(result.created_at, format: :full),
                          user: result.user.full_name), color: color[:gray]
            end
          end
          if !settings['exclude_task_metadata'] && result.steps.size.positive?
            text ' | '
            text I18n.t('projects.reports.elements.result.linked_steps'), color: color[:gray]
            text ' '
            text result.steps.map(&:label).join('; '), color: color[:gray]
          end
        end
        draw_result_asset(result, @settings) if @settings.dig('task', 'file_results')
        orderable_elements = @settings.dig('task', 'archived_results') ? result.all_elements : result.active_elements_ordered
        orderable_elements.each do |element|
          if @settings.dig('task', 'table_results') && element.is_a?(Table)
            draw_result_table(element)
          elsif @settings.dig('task', 'text_results') && element.is_a?(ResultText)
            draw_result_text(element)
          end
        end
        draw_result_comments(result) if @settings.dig('task', 'result_comments')
      end
    end
  end
end
