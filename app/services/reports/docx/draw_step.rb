# frozen_string_literal: true

module Reports::Docx::DrawStep
  def draw_step(step)
    color = @color
    step_type_str = step.completed ? 'completed' : 'uncompleted'
    user = (step.completed? && step.last_modified_by) || step.user
    timestamp = step.completed ? step.completed_on : step.created_at
    @docx.p
    @docx.h5(
      "#{I18n.t('projects.reports.elements.step.step_pos', pos: step.position_plus_one)} #{step.name}"
    )
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

    step.step_orderable_elements.order(:position).each do |element|
      case element.orderable_type
      when 'StepTable'
        handle_step_table(element.orderable.table)
      when 'Checklist'
        handle_checklist(element.orderable)
      when 'StepText'
        handle_step_text(element)
      end
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

  def handle_step_table(table)
    has_step_well_plates = @settings.dig('task', 'protocol', 'step_well_plates')
    has_step_tables = @settings.dig('task', 'protocol', 'step_tables')

    if table.metadata.present?
      if has_step_well_plates && table.metadata['plateTemplate']
        draw_step_table(table, 'step_well_plates_table')
      elsif has_step_tables && !table.metadata['plateTemplate']
        draw_step_table(table, 'step_table')
      end
    elsif has_step_tables
      draw_step_table(table, 'step_table')
    end
  end

  def handle_checklist(checklist)
    draw_step_checklist(checklist) if @settings.dig('task', 'protocol', 'step_checklists')
  end

  def handle_step_text(element)
    draw_step_text(element) if @settings.dig('task', 'protocol', 'step_texts')
  end
end
