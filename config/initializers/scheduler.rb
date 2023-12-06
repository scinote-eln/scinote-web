# frozen_string_literal: true

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

if ENV['ENABLE_TEMPLATES_SYNC'] == 'true'
  # Templates sync periodic task
  scheduler.every '12h' do
    Rails.logger.info('Templates, syncing all template projects')
    updated, total = TemplatesService.new.update_all_templates
    Rails.logger.info(
      "Templates, total number of updated projects: #{updated} out of #{total}}"
    )
    Rails.logger.flush
  end
end

if ENV['ENABLE_FLUICS_SYNC'] == 'true'
  scheduler.every '24h' do
    LabelPrinters::Fluics::SyncService.new.sync_templates! if LabelPrinter.fluics.any?
  end
end

reminder_job_interval = ENV['REMINDER_JOB_INTERVAL'] || '1h'

scheduler.every reminder_job_interval do
  MyModules::DueDateReminderJob.perform_now
  RepositoryItemDateReminderJob.perform_now
end

scheduler.every '1d' do
  NotificationCleanupJob.perform_now
end
