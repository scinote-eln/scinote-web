# frozen_string_literal: true

<<<<<<< HEAD
<<<<<<< HEAD
module Reports::Docx::DrawStep
<<<<<<< HEAD
<<<<<<< HEAD
  def draw_step(step)
    color = @color
    step_type_str = step.completed ? 'completed' : 'uncompleted'
    user = step.completed? && step.last_modified_by || step.user
    timestamp = step.completed ? step.completed_on : step.created_at
=======
module DrawStep
=======
module Reports::Docx::DrawStep
>>>>>>> Initial commit of 1.17.2 merge
  def draw_step(subject)
=======
  def draw_step(subject, my_module)
>>>>>>> Pulled latest release
=======
  def draw_step(step)
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    color = @color
    step_type_str = step.completed ? 'completed' : 'uncompleted'
<<<<<<< HEAD
    user = step.completed || !step.changed? ? step.user : step.last_modified_by
    timestamp = step.completed ? step.completed_on : step.updated_at
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    user = step.completed? ? step.last_modified_by : step.user
    timestamp = step.completed ? step.completed_on : step.created_at
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
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
<<<<<<< HEAD
<<<<<<< HEAD
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
=======
      html_to_word_converter(html)
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
      Reports::HtmlToWordConverter.new(@docx, { scinote_url: @scinote_url,
                                                link_style: @link_style }).html_to_word_converter(html)
>>>>>>> Pulled latest release
    else
      @docx.p I18n.t 'projects.reports.elements.step.no_description'
    end

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    if @settings.dig('task', 'protocol', 'step_tables')
      step.tables.each do |table|
        draw_step_table(table)
      end
    end
    if @settings.dig('task', 'protocol', 'step_files')
      step.assets.each do |asset|
        draw_step_asset(asset)
      end
<<<<<<< HEAD
    end
    if @settings.dig('task', 'protocol', 'step_checklists')
      step.checklists.each do |checklist|
        draw_step_checklist(checklist)
      end
    end
    draw_step_comments(step) if @settings.dig('task', 'protocol', 'step_comments')

=======
    subject['children'].each do |child|
      public_send("draw_#{child['type_of']}", child, step)
    end
>>>>>>> Finished merging. Test on dev machine (iMac).
=======
    end
    if @settings.dig('task', 'protocol', 'step_checklists')
      step.checklists.each do |checklist|
        draw_step_checklist(checklist)
      end
    end
    draw_step_comments(step) if @settings.dig('task', 'protocol', 'step_comments')

>>>>>>> Latest 1.22.0 release from biosistemika. All previous EPA changes revoked. Need to add in template.
    @docx.p
    @docx.p
  end
end
