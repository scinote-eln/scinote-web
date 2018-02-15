require_relative '../../app/services/tasks/samples_to_repository_migration_service'

namespace :samples_to_repository_migration do
  desc 'Migrates all data from samples to custom repository'
  task :run, [:last_id] => :environment do |_, args|
    params = { batch_size: 10 }
    migration_service = SamplesToRepositoryMigrationService
    if args.present? && args[:last_id].present?
      params[:start] = args[:last_id].to_i
    end
    Team.find_each(params) do |team|
      puts "******************************* \n\n\n\n"
      puts "Processing Team id => [#{team.id}] \n\n\n\n"
      puts '*******************************'

      samples_sql = <<-SQL
        SELECT samples.id AS sample_id,
               samples.name AS sample_name,
               samples.user_id AS sample_created_by_id,
               samples.last_modified_by_id AS sample_last_modified_by_id,
               sample_types.name AS sample_type_name,
               sample_groups.name AS sample_group_name,
               sample_groups.color AS sample_group_color
        FROM samples
        JOIN sample_types ON samples.sample_type_id = sample_types.id
        JOIN sample_groups ON samples.sample_type_id = sample_groups.id
        WHERE samples.team_id = #{team.id}
      SQL

      repository = migration_service.prepare_repository(team)
      custom_columns = migration_service.prepare_text_value_custom_columns(team, repository) +
                       migration_service.prepare_list_value_custom_columns_with_list_items(
                         team,
                         repository
                       )
      byebug
    end
  end
end
