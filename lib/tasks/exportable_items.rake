namespace :exportable_items do
  desc 'Removes exportable zip files'
  task cleanup: :environment do
    num = Constants::EXPORTABLE_ZIP_EXPIRATION_DAYS
    ZipExport.where('created_at < ?', num.days.ago).destroy_all
    puts "All exportable zip files older than " \
         "'#{num.days.ago}' have been removed"
  end

  desc 'Resets export project counter to 0'
  task reset_export_projects_counter: :environment do
    User.find_each do |user|
      User.transaction do
        begin
          user.export_vars['num_of_export_all_last_24_hours'] = 0
          user.save
        rescue ActiveRecord::ActiveRecordError,
               ArgumentError,
               ActiveRecord::RecordNotSaved => e
          puts "Error resetting users num_of_export_all_last_24_hours " \
               "variable to 0, transaction reverted: #{e}"
        end
      end
    end
    puts 'Export project counter successfully ' \
         'reset on all users'
  end
end
