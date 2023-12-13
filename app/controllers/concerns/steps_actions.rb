module StepsActions
  extend ActiveSupport::Concern
  # generates notification for smart annotations
  def create_annotation_notifications(step)
    # step description
    step_description_annotation(step)
    # checklists
    step.checklists.each do |checklist|
      checklist_name_annotation(step, checklist)
      checklist.checklist_items.each do |checklist_item|
        checklist_item_annotation(step, checklist_item)
      end
    end
  end

  # used for step update action it traverse through the input params and
  # generates notifications
  def update_annotation_notifications(step,
                                      old_description,
                                      new_checklists,
                                      old_checklists)
    step_description_annotation(step, old_description)
    new_checklists.each do |new_checklist|
      # generates smart annotaion if the checklist is new
      add_new_checklist(step, new_checklist) and next if new_checklist.id.zero?
      # else check if checklist is not deleted and generates
      # new notifications
      next unless old_checklists.map(&:id).include?(new_checklist.id)

      old_checklist = old_checklists.find { |i| i.id == new_checklist.id }
      checklist_name_annotation(step, new_checklist, old_checklist.name)
      new_checklist.items.each do |new_checklist_item|
        old_checklist_item = old_checklist.items.find { |i| i.id == new_checklist_item.id } if old_checklist
        text = old_checklist_item ? old_checklist_item.text : ''
        checklist_item_annotation(step, new_checklist_item, text)
      end
    end
  end

  def add_new_checklist(step, checklist)
    checklist_name_annotation(step, checklist)
    checklist.items.each do |ci|
      checklist_item_annotation(step, ci)
    end
  end

  def checklist_item_annotation(step, checklist_item, old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: checklist_item.text,
      subject: step.protocol,
      title: t('notifications.checklist_title',
               user: current_user.full_name,
               step: step.name),
      message: annotation_message(step)
    )
  end

  def step_text_annotation(step, step_text, old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: step_text.text,
      subject: step.protocol,
      title: t('notifications.step_text_title',
               user: current_user.full_name,
               step: step.name),
      message: annotation_message(step)
    )
  end

  def checklist_name_annotation(step, checklist, old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: checklist.name,
      subject: step.protocol,
      title: t('notifications.checklist_title',
               user: current_user.full_name,
               step: step.name),
      message: annotation_message(step)
    )
  end

  def step_description_annotation(step, old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: step.description,
      subject: step.protocol,
      title: t('notifications.step_description_title',
               user: current_user.full_name,
               step: step.name),
      message: annotation_message(step)
    )
  end

  def annotation_message(step)
    return t('notifications.step_annotation_message_html',
             project: link_to(
               step.my_module.experiment.project.name,
               project_url(step.my_module.experiment.project)
             ),
             experiment: link_to(
               step.my_module.experiment.name,
               my_modules_experiment_url(step.my_module.experiment)
             ),
             my_module: link_to(
               step.my_module.name,
               protocols_my_module_url(step.my_module)
             ),
             step: link_to(
               step.name,
               protocols_my_module_url(step.my_module)
             )) if @protocol.in_module?

    t('notifications.protocol_step_annotation_message_html',
      protocol: link_to(
        @protocol.name, edit_protocol_url(@protocol)
      ))
  end

  # temporary data containers
  PreviousChecklistItem = Struct.new(:id, :text)
  PreviousChecklist = Struct.new(:id, :name, :items) do
    def initialize(id, name, items = [])
      super(id, name, items)
    end

    def add_checklist(item)
      items << item
    end
  end
end
