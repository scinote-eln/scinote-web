class StepSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :name, :position, :completed, :urls

  def urls
    {
      delete_url: step_path(object),
      state_url: toggle_step_state_step_path(object),
      update_url: step_path(object),
      elements_url: elements_step_path(object),
      attachments_url: attachments_step_path(object),
      create_table_url: step_tables_path(object),
      create_text_url: step_texts_path(object),
      create_checklist_url: step_checklists_path(object)
    }
  end
end
