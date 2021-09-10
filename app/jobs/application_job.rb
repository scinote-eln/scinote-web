# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError

  def self.status(job_id)
    delayed_job = Delayed::Job.where('handler LIKE ?', "%job_id: #{job_id}%").last

    return :done unless delayed_job
    return :failed if delayed_job.failed_at
    return :running if delayed_job.locked_at

    :pending
  end
end
