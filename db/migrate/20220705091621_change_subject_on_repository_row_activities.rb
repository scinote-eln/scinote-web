# frozen_string_literal: true

class ChangeSubjectOnRepositoryRowActivities < ActiveRecord::Migration[6.1]
  def up
    execute(
      "UPDATE activities " \
      "SET subject_id = (values -> 'message_items' -> 'repository_row' ->> 'id')::bigint, "\
      "subject_type = 'RepositoryRow' " \
      "WHERE \"activities\".\"subject_type\" = 'RepositoryBase' "\
      "AND (values -> 'message_items' -> 'repository_row' IS NOT NULL);"
    )
  end

  def down
    Activity.where(subject_type: 'RepositoryRow').find_each do |activity|
      next if activity.subject.blank?

      activity.update_columns(subject_type: 'RepositoryBase', subject_id: activity.subject.repository_id)
    end
  end
end
