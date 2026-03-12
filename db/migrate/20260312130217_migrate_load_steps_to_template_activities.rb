# frozen_string_literal: true

class MigrateLoadStepsToTemplateActivities < ActiveRecord::Migration[7.2]
  def up
    Activity.where(type_of: 'protocol_steps_loaded_from_template').find_each do |activity|
      protocol_target = activity.subject

      if protocol_target
        activity.values['message_items']['protocol_target'] = {
          'id' => protocol_target.id,
          'type' => 'Protocol',
          'value' => protocol_target.name,
          'value_for' => 'name'
        }

        activity.save!
      end
    end
  end

  def down
    Activity.where(type_of: 'protocol_steps_loaded_from_template').find_each do |activity|
      activity.values['message_items'].delete('protocol_target')
      activity.save!
    end
  end
end
