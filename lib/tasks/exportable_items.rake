# frozen_string_literal: true

namespace :exportable_items do
  desc 'Removes exportable zip files'
  task cleanup: :environment do
    num = Constants::EXPORTABLE_ZIP_EXPIRATION_DAYS
    ZipExport.where('created_at < ?', num.days.ago).destroy_all
    puts "All exportable zip files older than " \
         "'#{num.days.ago}' have been removed"
  end
end
