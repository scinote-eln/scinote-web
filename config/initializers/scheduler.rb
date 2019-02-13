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
