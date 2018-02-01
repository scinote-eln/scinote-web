# DelayedWorkerConfig is a configuration object that parses and sanitize
# environmental variables. @note Used only for Delayed::Worker settings
module DelayedWorkerConfig
  module_function

  # If you want to keep failed jobs, set DELAYED_WORKER_DESTROY_FAILED_JOBS to
  # false. The failed jobs will be marked with non-null failed_at.
  def destroy_failed_jobs
    value = ENV['DELAYED_WORKER_DESTROY_FAILED_JOBS']
    return false unless value
    return false unless value.in? %w(true 1)
    true
  end

  # If no jobs are found, the worker sleeps for the amount of time specified by
  # the sleep delay option. Default to 60 second.
  def sleep_delay
    value = ENV['DELAYED_WORKER_SLEEP_DELAY'].to_i
    return 60 if value.zero?
    value
  end

  # The default is 6 attempts. After this, the job either deleted
  # or left in the database with "failed_at" set dempends on the
  # DESTROY_FAILED_JOBS value
  def max_attempts
    value = ENV['DELAYED_WORKER_MAX_ATTEMPTS'].to_i
    return 6 if value.zero?
    value
  end

  # The default DELAYED_WORKER_MAX_RUN_TIME is 30.minutes.
  # If your job takes longer than that, another computer could pick it up.
  # It's up to you to make sure your job doesn't exceed this time.
  # You should set this to the longest time you think the job could take.
  def max_run_time
    value = ENV['DELAYED_WORKER_MAX_RUN_TIME'].to_i
    return 30.minutes if value.zero?
    value.minutes
  end

  # The default behavior is to read 10 jobs from the queue when finding an
  # available job. You can configure this by setting.
  def read_ahead
    value = ENV['DELAYED_WORKER_READ_AHEAD'].to_i
    return 10 if value.zero?
    value
  end

  # By default all jobs will be queued without a named queue.
  # A default named queue can be specified by using
  def default_queue_name
    value = ENV['DELAYED_WORKER_DEFAULT_QUEUE_NAME']
    return 'default' unless value
    value
  end
end

# Delayed::Worker configuration
Delayed::Worker.destroy_failed_jobs = DelayedWorkerConfig.destroy_failed_jobs
Delayed::Worker.sleep_delay = DelayedWorkerConfig.sleep_delay
Delayed::Worker.max_attempts = DelayedWorkerConfig.max_attempts
Delayed::Worker.max_run_time = DelayedWorkerConfig.max_run_time
Delayed::Worker.read_ahead = DelayedWorkerConfig.read_ahead
Delayed::Worker.default_queue_name = DelayedWorkerConfig.default_queue_name
