require_relative '../../app/services/tasks/samples_to_repository_migration_service'

namespace :samples_to_repository_migration do
  desc 'Migrates all data from samples to custom repository'
  task :run, [:last_id] => :environment do |_, args|
    include ActiveRecord::Sanitization::ClassMethods

    params = { batch_size: 10 }
    migration_service = Tasks::SamplesToRepositoryMigrationService
    conn = ActiveRecord::Base.connection
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
        sample_mappings = {}
        team_samples.each do |item|
          created_by = item['sample_created_by_id'] || team.created_by_id
          last_modified_by = item['sample_last_modified_by_id']
          last_modified_by ||= team.created_by_id
          timestamp = conn.quote(Time.now.to_s(:db))
          values = [repository.id, created_by, last_modified_by,
                    conn.quote(item['sample_name']), timestamp, timestamp]
          list_item_sql = <<-SQL
            INSERT INTO repository_rows
              (repository_id, created_by_id, last_modified_by_id, name,
               created_at, updated_at)
            VALUES (#{values.join(', ')})
            RETURNING id
          SQL
          result = conn.execute(list_item_sql)
          row_id = result[0]['id']
          sample_mappings[item['sample_id']] = row_id

          # check if sample has sample type assigned
          if item['sample_type_name']
            column = custom_columns.detect { |el| el['name'] == 'Sample type' }
            list_item = column.repository_list_items.where(
              data: item['sample_type_name']
            ).take
            migration_service.create_list_cell(
              row_id, column.id, list_item.id,
              list_item.created_by_id, list_item.last_modified_by_id
            )
          end

          # check if sample has sample group assigned
          if item['sample_group_name']
            column = custom_columns.detect { |el| el['name'] == 'Sample group' }
            list_item = column.repository_list_items.where(
              data: item['sample_group_name']
            ).take
            migration_service.create_list_cell(
              row_id, column.id, list_item.id,
              list_item.created_by_id, list_item.last_modified_by_id
            )

            # assign sample group color to the sample
            if item['sample_group_color']
              column = custom_columns.detect do |el|
                el['name'] == 'Sample group color hex'
              end
              migration_service.create_text_cell(
                row_id, column.id, item['sample_group_color'],
                created_by, last_modified_by
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
            migration_service
              .create_text_cell(row_id, column.id, field['value'],
                                created_by, last_modified_by)
          end

          # assign repository item to a tasks
          assigned_modules = migration_service.get_assigned_sample_module(
            item['sample_id']
          )
          assigned_modules.each do |element|
            assigned_by = element['assigned_by_id'] || created_by
            values = [row_id, element['my_module_id'], assigned_by,
                      timestamp, timestamp]
            cell_sql = <<-SQL
              INSERT INTO my_module_repository_rows
                (repository_row_id, my_module_id, assigned_by_id,
                 created_at, updated_at)
              VALUES (#{values.join(', ')})
            SQL
            conn.execute(cell_sql)
          end
        end

        # Update report elements
        team.reports.each do |r|
          r.report_elements.where(type_of: 7).each do |e|
            e.update(type_of: 17, repository_id: repository.id)
          end
        end

        # Now update smart annotations
        migration_service.update_smart_annotations(team, sample_mappings)
      end
    end
  end
end
