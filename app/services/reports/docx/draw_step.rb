# frozen_string_literal: true

module Reports::Docx::DrawStep
  def draw_step(step)
    color = @color
    step_type_str = step.completed ? 'completed' : 'uncompleted'
    user = step.completed? && step.last_modified_by || step.user
    timestamp = step.completed ? step.completed_on : step.created_at
    @docx.p
    @docx.h5 (I18n.t('projects.reports.elements.step.step_pos', pos: step.position_plus_one) +
             ' ' + step.name), size: Constants::REPORT_DOCX_STEP_TITLE_SIZE
    @docx.p do
      if step.completed
        text I18n.t('protocols.steps.completed'), color: color[:green], bold: true
      else
        text I18n.t('protocols.steps.uncompleted'), color: color[:gray], bold: true
      end
      text ' | '
      text I18n.t(
        "projects.reports.elements.step.#{step_type_str}.user_time",
        user: user.full_name,
        timestamp: I18n.l(timestamp, format: :full)
      ), color: color[:gray]
    end
    if step.description.present?
      html = custom_auto_link(step.description, team: @report_team)
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
    else
      @docx.p I18n.t 'projects.reports.elements.step.no_description'
    end

    step.step_orderable_elements.order(:position).each do |e|
      if e.orderable_type == 'StepTable' && @settings.dig('task', 'protocol', 'step_tables')
        draw_step_table(e.orderable.table)
      end
      if e.orderable_type == 'Checklist' && @settings.dig('task', 'protocol', 'step_checklists')
        draw_step_checklist(e.orderable)
      end
      draw_step_text(e.orderable) if e.orderable_type == 'StepText' && @settings.dig('task', 'protocol', 'step_texts')
    end
    if @settings.dig('task', 'protocol', 'step_files')
      step.assets.each do |asset|
        draw_step_asset(asset)
      end
    end

    draw_step_comments(step) if @settings.dig('task', 'protocol', 'step_comments')

    @docx.p
    @docx.p
  end
end
