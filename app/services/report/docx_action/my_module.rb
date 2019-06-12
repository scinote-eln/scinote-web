# frozen_string_literal: true

# rubocop:disable  Style/ClassAndModuleChildren
module Report::DocxAction::MyModule
  def draw_my_module(my_module, children)
    scinote_url = @scinote_url
    @docx.h3 my_module.name, italic: false
    @docx.p do
      text I18n.t('projects.reports.elements.module.user_time',
                  timestamp: I18n.l(my_module.created_at, format: :full)), color: 'a0a0a0'
      text ' | '
      if my_module.due_date.present?
        text I18n.t('projects.reports.elements.module.due_date',
                    due_date: I18n.l(my_module.due_date, format: :full)), color: 'a0a0a0'
      else
        text I18n.t('projects.reports.elements.module.no_due_date'), color: 'a0a0a0'
      end
      if my_module.completed?
        text " #{I18n.t('my_modules.states.completed')} #{I18n.l(my_module.completed_on, format: :full)}",
             color: 'a0a0a0'
      end
      text ' | '
      link  'SciNote Link',
            scinote_url + Rails.application.routes.url_helpers.protocols_my_module_path(my_module),
            @link_style
    end
    if my_module.description.present?
      html = custom_auto_link(my_module.description, team: @report_team)
      html_to_word_converter(html)
    else
      @docx.p I18n.t 'projects.reports.elements.module.no_description'
    end

    @docx.p do
      text I18n.t 'projects.reports.elements.module.tags_header'
      my_module.tags.each do |tag|
        text ' ' + tag.name, color: tag.color.delete('#')
      end
    end

    @docx.p
    draw_protocol(my_module.protocol)
    children.each do |my_module_hash|
      case my_module_hash['type_of']
      when 'step'
        step = ::Step.find_by_id(my_module_hash['id']['step_id'])
        draw_step(step, my_module_hash['children']) if step
      when 'my_module_activity'
        draw_my_module_activity(my_module, my_module_hash['sort_order'])
      when 'result_asset'
        result = Result.find_by_id(my_module_hash['id']['result_id'])
        draw_result_asset(result, my_module_hash['children']) if result
      when 'result_table'
        result = Result.find_by_id(my_module_hash['id']['result_id'])
        draw_result_table(result, my_module_hash['children']) if result
      when 'result_text'
        result = Result.find_by_id(my_module_hash['id']['result_id'])
        draw_result_text(result, my_module_hash['children']) if result
      when 'my_module_repository'
        draw_my_module_samples(my_module, my_module_hash['id']['repository_id'], my_module_hash['sort_order'])
      end
    end
  end
end
# rubocop:enable  Style/ClassAndModuleChildren
