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

  def fetch_new_checklists_data
    checklists = []
    new_checklists = step_params[:checklists_attributes]

    if new_checklists
      new_checklists.to_h.each do |e|
        list = PreviousChecklist.new(
          e.second[:id].to_i,
          e.second[:name]
        )
        if e.second[:checklist_items_attributes]
          e.second[:checklist_items_attributes].each do |el|
            list.add_checklist(
              PreviousChecklistItem.new(el.second[:id].to_i, el.second[:text])
            )
          end
        end
        checklists << list
      end
    end
    checklists
  end

  def fetch_old_checklists_data(step)
    checklists = []
    if step.checklists
      step.checklists.each do |e|
        list = PreviousChecklist.new(
          e.id,
          e.name
        )
        e.checklist_items.each do |el|
          list.add_checklist(
            PreviousChecklistItem.new(el.id, el.text)
          )
        end
        checklists << list
      end
    end
    checklists
  end

  # used for step update action it traverse through the input params and
  # generates notifications
  def update_annotation_notifications(step,
                                      old_description,
                                      new_checklists,
                                      old_checklists)
    step_description_annotation(step, old_description)
    new_checklists.each do |e|
      # generates smart annotaion if the checklist is new
      add_new_checklist(step, e) if e.id.zero?
      checklist_name_annotation(step, e) unless e.id
      # else check if checklist is not deleted and generates
      # new notifications
      next unless old_checklists.map(&:id).include?(e.id)
      old_checklist = old_checklists.select { |i| i.id == e.id }.first
      checklist_name_annotation(step, e, old_checklist.name)
      e.items.each do |ci|
        old_list = old_checklists.select { |i| i.id == e.id }.first
        old_item = old_list.items.select { |i| i.id == ci.id }.first if old_list
        text = old_item ? old_item.text : ''
        checklist_item_annotation(step, ci, text)
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
      title: t('notifications.checklist_title',
               user: current_user.full_name,
               step: step.name),
      message: annotation_message(step)
    )
  end

  def checklist_name_annotation(step, checklist, old_text = nil)
    smart_annotation_notification(
      old_text: old_text,
      new_text: checklist.name,
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
               canvas_experiment_url(step.my_module.experiment)
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
