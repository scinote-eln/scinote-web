# frozen_string_literal: true

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.singleton

if ENV['ENABLE_TEMPLATES_SYNC'] && ARGV[0] == 'jobs:work'
  # Templates sync periodic task
  scheduler.every '1h' do
    Rails.logger.info('Templates, syncing all template projects')
    updated, total = TemplatesService.new.update_all_templates
    Rails.logger.info(
      "Templates, total number of updated projects: #{updated} out of #{total}}"
    )
    Rails.logger.flush
  end
end

if Rails.application.secrets.system_notifications_uri.present? &&
   Rails.application.secrets.system_notifications_channel.present? &&
   ARGV[0] == 'jobs:work'

  # System notifications periodic task
  scheduler.every '5m' do
    Rails.logger.info('System Notifications syncing')
    Rails.logger.info(Process.pid)
    result = Notifications::SyncSystemNotificationsService.call
    if result.errors.any?
      Rails.logger.info('System Notifications sync error: ')
      Rails.logger.info(result.errors.to_s)
    else
      Rails.logger.info('System Notifications sync done')
    end
  end
end
