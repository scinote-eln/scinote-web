# frozen_string_literal: true

class AddParentToFormResponses < ActiveRecord::Migration[7.0]
  def up
    add_reference :form_responses, :parent, polymorphic: true

    FormResponse.find_each do |form_response|
      form_response.update(parent_type: 'Step', parent_id: form_response.step.id)
    end
  end

  def down
    remove_reference :form_responses, :parent, polymorphic: true
  end
end
