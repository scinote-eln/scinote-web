namespace :notifications do
  desc 'Creates new system notification for all active users'
  task :new_system, [:title, :message] => :environment do |_, args|
    include NotificationsHelper

    if args.blank? ||
       args.empty? ||
       args[:title].blank? ||
       args[:message].blank?
      puts 'One or both of arguments are missing'
      return
    end

    title = args[:title]
    message = args[:message]

    puts 'Creating following system notification:'
    puts "    ***  #{title} ***"
    puts "    #{I18n.l(Time.now, format: :full)} | #{message}"

    create_system_notification(title, message)
  end
end
