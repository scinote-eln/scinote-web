# frozen_string_literal: true

module DrawMyModule
  def draw_my_module(subject)
    color = @color
    link_style = @link_style
    scinote_url = @scinote_url
    my_module = MyModule.find_by_id(subject['id']['my_module_id'])
    return unless my_module

    @docx.h3 my_module.name, italic: false
    @docx.p do
      text I18n.t('projects.reports.elements.module.user_time',
                  timestamp: I18n.l(my_module.created_at, format: :full)), color: color[:gray]
      text ' | '
      if my_module.due_date.present?
        text I18n.t('projects.reports.elements.module.due_date',
                    due_date: I18n.l(my_module.due_date, format: :full)), color: color[:gray]
      else
        text I18n.t('projects.reports.elements.module.no_due_date'), color: color[:gray]
      end
      if my_module.completed?
        text " #{I18n.t('my_modules.states.completed')} #{I18n.l(my_module.completed_on, format: :full)}",
             color: color[:gray]
      end
      text ' | '
      link  'SciNote Link',
            scinote_url + Rails.application.routes.url_helpers.protocols_my_module_path(my_module),
            link_style
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
        text ' '
        text tag.name, color: tag.color.delete('#')
      end
    end

    @docx.p
    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
    end
  end
end
