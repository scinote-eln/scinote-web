# frozen_string_literal: true

class AddIncludeSerializedSubjectToWebhooks < ActiveRecord::Migration[7.0]
  def change
    add_column :webhooks, :include_serialized_subject, :boolean, null: false, default: false
  end
end
