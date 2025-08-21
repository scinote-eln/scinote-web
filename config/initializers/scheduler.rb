# frozen_string_literal: true

require 'rufus-scheduler'

def schedule_task(scheduler, interval, &block)
  # Introduce a special time jitter for better load distribution
  schedule_jitter = %w(12h 24h 1d).include?(interval) ? "#{rand(3)}h#{rand(60)}m" : "#{rand(60)}m"
  scheduler.in schedule_jitter do
    scheduler.every interval do
      ActiveRecord::Base.connection_pool.with_connection(&block)
    end
  end
end

if ENV['WORKER'].present?
  scheduler = Rufus::Scheduler.singleton

  if ENV['ENABLE_TEMPLATES_SYNC'] == 'true'
    schedule_task(scheduler, '12h') do
      Rails.logger.info('Templates, syncing all template projects')
      updated, total = TemplatesService.new.update_all_templates
      Rails.logger.info(
        "Templates, total number of updated projects: #{updated} out of #{total}}"
      )
    end
  end

  if ENV['ENABLE_FLUICS_SYNC'] == 'true'
    schedule_task(scheduler, '24h') do
      LabelPrinters::Fluics::SyncService.new.sync_templates! if LabelPrinter.fluics.any?
    end
  end

  reminder_job_interval = ENV['REMINDER_JOB_INTERVAL'] || '1h'
  schedule_task(scheduler, reminder_job_interval) do
    ProjectDueDateReminderJob.perform_now
    ExperimentDueDateReminderJob.perform_now
    MyModules::DueDateReminderJob.perform_now
    RepositoryItemDateReminderJob.perform_now
  end

  if ENV['WOPI_ENABLED'] == 'true'
    # Clean up expired WOPI tokens
    schedule_task(scheduler, '1d') do
      Token.where(ttl: ...Time.now.utc.to_i).delete_all
    end
  end

  schedule_task(scheduler, '1d') do
    NotificationCleanupJob.perform_now
  end
end
