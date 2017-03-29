namespace :exportable_items do
  desc 'Removes exportable zip files if older than 3 days'
  task cleanup: :environment do
    ZipExport.where('created_at < ?', 3.days.ago).destroy_all
    puts "All exportable zip files older than '#{3.days.ago}' have been removed"
  end
end
