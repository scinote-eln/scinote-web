namespace :notifications do

  desc 'Creates new system notification for all active users'
  task :new_release => :environment do
    include NotificationsHelper
    puts 'Creation of system notification for all active users with link to release notes'
    create_system_notification('New release', 'http://scinote.net/docs/release-notes/')
  end

end
