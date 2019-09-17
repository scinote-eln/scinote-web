# frozen_string_literal: true

module Reports::Docx::DrawMyModule
  def draw_my_module(subject)
    color = @color
    link_style = @link_style
    scinote_url = @scinote_url
    my_module = MyModule.find_by_id(subject['id']['my_module_id'])
    tags = my_module.tags
    return unless my_module

    @docx.h3 my_module.name, italic: false, size: Constants::REPORT_DOCX_MY_MODULE_TITLE_SIZE
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
        text " #{I18n.t('my_modules.states.completed')}", bold: true, color: color[:green]
        text " #{I18n.l(my_module.completed_on, format: :full)}", color: color[:gray]
      end
      if my_module.archived?
        text ' | '
        text I18n.t('search.index.archived'), color: color[:gray]
      end
      text ' | '
      link  I18n.t('projects.reports.elements.all.scinote_link'),
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
      if tags.any?
        my_module.tags.each do |tag|
          text ' '
          text "[#{tag.name}]", color: tag.color.delete('#')
        end
      else
        text ' '
        text I18n.t 'projects.reports.elements.module.no_tags'
      end
    end

    @docx.p
    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
    end
  end
end
