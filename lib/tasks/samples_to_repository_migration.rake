require_relative '../../app/services/tasks/samples_to_repository_migration_service'

namespace :samples_to_repository_migration do
  desc 'Migrates all data from samples to custom repository'
  task :run, [:last_id] => :environment do |_, args|
    params = { batch_size: 10 }
    migration_service = Tasks::SamplesToRepositoryMigrationService
    if args.present? && args[:last_id].present?
      params[:start] = args[:last_id].to_i
    end
    Team.find_each(params) do |team|
      puts "******************************* \n\n\n\n"
      puts "Processing Team id => [#{team.id}] \n\n\n\n"
      puts '*******************************'
      # byebug
      migration_service.fetch_all_team_samples(team)

      repository = migration_service.prepare_repository(team)
      custom_columns = migration_service.prepare_text_value_custom_columns(team, repository) +
                       migration_service.prepare_list_value_custom_columns_with_list_items(
                         team,
                         repository
                       )
      # byebug
    end
  end
end
