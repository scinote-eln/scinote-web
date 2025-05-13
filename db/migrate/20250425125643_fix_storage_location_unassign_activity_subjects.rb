# frozen_string_literal: true

class FixStorageLocationUnassignActivitySubjects < ActiveRecord::Migration[7.0]
  def up
    Activity.where(type_of: :storage_location_repository_row_deleted).where.not(subject_type: 'StorageLocation').find_each do |activity|
      activity.update!(
        subject_type: 'StorageLocation',
        subject_id: activity.values.dig('message_items', 'storage_location', 'id')
      )
    end
  end

  def down
    # do nothing
  end
end
