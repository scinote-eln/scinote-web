# frozen_string_literal: true

class AddPreviousFormResponsesValueToFormResponse < ActiveRecord::Migration[7.0]
  def change
    add_reference :form_responses, :previous_form_response, foreign_key: { to_table: :form_responses }
  end
end
