# frozen_string_literal: true

module Reports::Docx::DrawStep
  def draw_step(subject)
    color = @color
    step = Step.find_by_id(subject['id']['step_id'])
    return unless step

    step_type_str = step.completed ? 'completed' : 'uncompleted'
    user = step.completed || !step.changed? ? step.user : step.last_modified_by
    timestamp = step.completed ? step.completed_on : step.updated_at
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
      html_to_word_converter(html)
    else
      @docx.p I18n.t 'projects.reports.elements.step.no_description'
    end

    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child)
    end
    @docx.p
    @docx.p
  end
end
