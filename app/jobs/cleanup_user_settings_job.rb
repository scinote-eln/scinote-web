# frozen_string_literal: true

class CleanupUserSettingsJob < ApplicationJob
  queue_as :default

  def perform(record_type, record_id)
    raise ArgumentError, 'Invalid record_type' unless %w(task_step_states results_order).include?(record_type)

    sanitized_record_id = record_id.to_i.to_s
    raise ArgumentError, 'Invalid record_id' unless sanitized_record_id == record_id.to_s

    sql = <<-SQL.squish
      UPDATE users
      SET settings = (settings#>>'{}')::jsonb #- '{#{record_type},#{sanitized_record_id}}'
      WHERE (settings#>>'{}')::jsonb->'#{record_type}' ? '#{sanitized_record_id}';
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
