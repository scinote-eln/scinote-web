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
      puts "******************************* \n\n"
      puts "Processing Team id => [#{team.id}] \n\n"
      puts '*******************************'

      ActiveRecord::Base.transaction do
        team_samples = migration_service.fetch_all_team_samples(team)
        repository = migration_service.prepare_repository(team)
        custom_columns = migration_service.get_custom_columns(team, repository)

        team_samples.each do |item|
          created_by = item['sample_created_by_id'] || team.created_by_id
          last_modified_by = item['sample_last_modified_by_id']
          last_modified_by ||= team.created_by_id
          row = RepositoryRow.create!(
            name: item['sample_name'],
            created_at: item['sample_created_at'],
            updated_at: item['sample_updated_at'],
            created_by_id: created_by,
            last_modified_by_id: last_modified_by,
            repository: repository
          )
          # check if sample has sample type assigned
          if item['sample_type_name']
            column = custom_columns.detect { |el| el['name'] == 'Sample type' }
            list_item = column.repository_list_items.where(
              data: item['sample_type_name']
            ).take
            RepositoryListValue.create!(
              created_by: list_item.created_by,
              last_modified_by: list_item.last_modified_by,
              repository_list_item: list_item,
              repository_cell_attributes: {
                repository_row: row,
                repository_column: column
              }
            )
          end

          # check if sample has sample group assigned
          if item['sample_group_name']
            column = custom_columns.detect { |el| el['name'] == 'Sample group' }
            list_item = column.repository_list_items.where(
              data: item['sample_group_name']
            ).take
            RepositoryListValue.create!(
              created_by: list_item.created_by,
              last_modified_by: list_item.last_modified_by,
              repository_list_item: list_item,
              repository_cell_attributes: {
                repository_row: row,
                repository_column: column
              }
            )

            # assign sample group color to the sample
            if item['sample_group_color']
              column = custom_columns.detect do |el|
                el['name'] == 'Sample group color hex'
              end
              RepositoryTextValue.create!(
                data: item['sample_group_color'],
                created_by_id: created_by,
                last_modified_by_id: last_modified_by,
                repository_cell_attributes: {
                  repository_row: row,
                  repository_column: column
                }
              )
            end
          end

          # append custom fields
          custom_fields = migration_service.get_sample_custom_fields(
            item['sample_id']
          )
          custom_fields.each do |field|
            column = custom_columns.detect do |el|
              el['name'] == field['column_name_reference']
            end
            RepositoryTextValue.create!(
              data: field['value'],
              created_by_id: created_by,
              last_modified_by_id: last_modified_by,
              repository_cell_attributes: {
                repository_row: row,
                repository_column: column
              }
            )
          end

          # assign repository item to a tasks
          assigned_modules = migration_service.get_assigned_sample_module(
            item['sample_id']
          )
          assigned_modules.each do |element|
            MyModuleRepositoryRow.create!(
              my_module_id: element['my_module_id'],
              repository_row: row,
              assigned_by_id: element['assigned_by_id'] || created_by
            )
          end
        end
      end
    end
  end
end
