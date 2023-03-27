namespace :db do
  desc 'Generate migration files for adding an index to the archived column of all tables that have one'
  task :generate_archived_indexes_migrations => :environment do
    ActiveRecord::Base.connection.tables.each do |table|
      next unless ActiveRecord::Base.connection.column_exists?(table, :archived)

      migration_name = "add_index_to_#{table}"
      rails_generate_command = "rails generate migration #{migration_name} archived:boolean:index"
      system(rails_generate_command)
    end
  end
end
