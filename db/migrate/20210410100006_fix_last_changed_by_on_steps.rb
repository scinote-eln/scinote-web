# frozen_string_literal: true

class Step < ApplicationRecord
  # Making sure we don't get undesired callbacks in the future
  # But still enjoy the handyness of using the model
end

class FixLastChangedByOnSteps < ActiveRecord::Migration[6.1]
  # There was an issue with API steps endpoint not settings last_modified_by_id
  # this migration fix the affected records
  # At the moment it seems only the complete and uncomplete actions were problematic
  #
  # The enterprise build of SciNote also uses the Audit Trails
  # In this instance we don't neet to worry about these changes
  # because we're not recording the changes to last_modified_by_id

  def up
    Step.where(last_modified_by_id: nil).find_each do |step|
      # Try to find corresponding activity, if step was changed activity should exist
      # we cannot completely rely on that, so for the fallback we use the step user
      activity = Activity
                 .where(type_of: %i(complete_step uncomplete_step))
                 .where("values -> 'message_items' -> 'step' ->> 'id' = ?", step.id.to_s)
                 .order(created_at: :desc)
                 .first
      if activity && user_id = activity.values.dig('message_items', 'user', 'id')
        step.update_column(:last_modified_by_id, user_id)
      else
        step.update_column(:last_modified_by_id, step.user_id)
      end
    end
  end
end
