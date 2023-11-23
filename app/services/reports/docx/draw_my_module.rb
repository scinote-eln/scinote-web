# frozen_string_literal: true

module Reports::Docx::DrawMyModule
  def draw_my_module(subject)
    color = @color
    link_style = @link_style
    scinote_url = @scinote_url
    my_module = subject.my_module
    tags = my_module.tags.order(:id)
    return unless can_read_my_module?(@user, my_module)

    @docx.h3 do
      link  my_module.name,
            scinote_url + Rails.application.routes.url_helpers.protocols_my_module_path(my_module),
            link_style
    end

    @docx.p do
      text I18n.t('projects.reports.elements.module.user_time', code: my_module.code,
                  timestamp: I18n.l(my_module.created_at, format: :full)), color: color[:gray]
      if my_module.archived?
        text ' | '
        text I18n.t('search.index.archived'), color: color[:gray]
      end
    end

    if my_module.started_on.present?
      @docx.p do
        text I18n.t('projects.reports.elements.module.started_on',
                    started_on: I18n.l(my_module.started_on, format: :full))
      end
    end

    if my_module.due_date.present?
      @docx.p do
        text I18n.t('projects.reports.elements.module.due_date',
                    due_date: I18n.l(my_module.due_date, format: :full))
      end
    end

    status = my_module.my_module_status
    @docx.p do
      text I18n.t('projects.reports.elements.module.status')
      text ' '
      text "[#{status.name}]", color: (status.light_color? ? '000000' : status.color.delete('#'))
      if my_module.completed?
        text " #{I18n.t('my_modules.states.completed')} #{I18n.l(my_module.completed_on, format: :full)}"
      end
    end

    if tags.present?
      @docx.p do
        text I18n.t('projects.reports.elements.module.tags_header')
        tags.each do |tag|
          text ' '
          text "[#{tag.name}]", color: tag.color.delete('#')
        end
      end
    end

    if my_module.description.present?
      html = custom_auto_link(my_module.description, team: @report_team)
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: scinote_url,
                                                link_style: link_style }).html_to_word_converter(html)
    end

    draw_my_module_protocol(my_module)

    filter_steps_for_report(my_module.protocol.steps, @settings).order(:position).each do |step|
      draw_step(step)
    end

    if my_module.results.any? && (%w(file_results table_results text_results).any? { |k| @settings.dig('task', k) })
      @docx.h4 I18n.t('Results')
      order_results_for_report(my_module.results, @settings.dig('task', 'result_order')).each do |result|
        @docx.p do
          text result.name.presence || I18n.t('projects.reports.unnamed'), italic: true
          text "  #{I18n.t('search.index.archived')} ", bold: true if result.archived?
          text I18n.t('projects.reports.elements.result.user_time',
                      timestamp: I18n.l(result.created_at, format: :full),
                      user: result.user.full_name), color: color[:gray]
        end
        draw_result_asset(result, @settings) if @settings.dig('task', 'file_results')
        result.result_orderable_elements.each do |element|
          if @settings.dig('task', 'table_results') && element.orderable_type == 'ResultTable'
            draw_result_table(element)
          elsif @settings.dig('task', 'text_results') && element.orderable_type == 'ResultText'
            draw_result_text(element)
          end
        end
        draw_result_comments(result) if @settings.dig('task', 'result_comments')
      end
    end

    @docx.p
    subject.children.active.each do |child|
      public_send("draw_#{child.type_of}", child)
    end

    draw_my_module_activity(my_module) if @settings.dig('task', 'activities')
  end
end
