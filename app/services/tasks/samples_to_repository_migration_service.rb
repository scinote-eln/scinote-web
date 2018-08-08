# frozen_string_literal: true

# Helper module for dealing with the migration from samples
# to custom repositories. We need to query with SQL because probably we will not
# have the "Sample" and other related models at the time this code will execute

module Tasks
  module SamplesToRepositoryMigrationService
    include ActiveRecord::Sanitization::ClassMethods

    def self.prepare_repository(team, copy_num = 0)
      repository = Repository.new(
        name: copy_num > 0 ? "Samples (#{copy_num})" : 'Samples',
        team: team,
        created_by: team.created_by
      )
      return repository if repository.save
      prepare_repository(team, copy_num + 1)
    end

    def self.prepare_text_value_custom_columns(team, repository)
      custom_columns_sql = <<-SQL
        SELECT * FROM custom_fields WHERE team_id = #{team.id}
      SQL
      # execute query
      custom_columns = ActiveRecord::Base.connection.execute(custom_columns_sql)

      repository_columns = []
      custom_columns.each_with_index do |column, index|
        repository_column = RepositoryColumn.create!(
          repository: repository,
          created_by_id: column.fetch('user_id') { repository.created_by_id },
          data_type: :RepositoryTextValue,
          name: column.fetch('name') { "Custom column (#{index})" },
          created_at: column.fetch('created_at') { DateTime.now },
          updated_at: column.fetch('updated_at') { DateTime.now }
        )
        repository_columns << repository_column
      end
      repository_columns
    end

    def self.prepare_list_value_custom_columns_with_list_items(team, repository)
      conn = ActiveRecord::Base.connection
      sample_types_sql = <<-SQL
        SELECT name, created_by_id, last_modified_by_id
        FROM sample_types
        WHERE team_id = #{team.id}
      SQL
      sample_groups_sql = <<-SQL
        SELECT name, created_by_id, last_modified_by_id
        FROM sample_groups
        WHERE team_id = #{team.id}
      SQL
      # execute query
      sample_types = conn.execute(sample_types_sql)
      sample_groups = conn.execute(sample_groups_sql)

      sample_group = RepositoryColumn.create!(
        repository: repository,
        created_by_id: repository.created_by_id,
        data_type: :RepositoryListValue,
        name: 'Sample group'
      )

      # needs some random string to prevent duplications error
      sample_group_color = RepositoryColumn.create!(
        repository: repository,
        created_by_id: repository.created_by_id,
        data_type: :RepositoryTextValue,
        name: 'Sample group color hex'
      )

      sample_type = RepositoryColumn.create!(
        repository: repository,
        created_by_id: repository.created_by_id,
        data_type: :RepositoryListValue,
        name: 'Sample type'
      )

      sample_groups.each_with_index do |item, index|
        created_by = item['created_by_id'] || team.created_by_id
        last_modified_by = item['last_modified_by_id'] || team.created_by_id
        timestamp = conn.quote(Time.now.to_s(:db))
        values = [
          repository.id,
          sample_group.id,
          conn.quote(item.fetch('name') { "sample group item (#{index})" }),
          created_by,
          last_modified_by,
          timestamp,
          timestamp
        ]
        list_item_sql = <<-SQL
          INSERT INTO repository_list_items
            (repository_id,
             repository_column_id,
             data,
             created_by_id,
             last_modified_by_id,
             created_at, updated_at)
          VALUES (#{values.join(', ')})
        SQL
        conn.execute(list_item_sql)
      end

      sample_types.each_with_index do |item, index|
        created_by = item['created_by_id'] || team.created_by_id
        last_modified_by = item['last_modified_by_id'] || team.created_by_id
        timestamp = conn.quote(Time.now.to_s(:db))
        values = [
          repository.id,
          sample_type.id,
          conn.quote(item.fetch('name') { "sample type item (#{index})" }),
          created_by,
          last_modified_by,
          timestamp,
          timestamp
        ]
        list_item_sql = <<-SQL
          INSERT INTO repository_list_items
            (repository_id,
             repository_column_id,
             data,
             created_by_id,
             last_modified_by_id,
             created_at, updated_at)
          VALUES (#{values.join(', ')})
        SQL
        conn.execute(list_item_sql)
      end

      [sample_group, sample_type, sample_group_color]
    end

    def self.get_sample_custom_fields(sample_id)
      custom_sample_fields_sql = <<-SQL
        SELECT custom_fields.name AS column_name_reference,
               sample_custom_fields.value,
               sample_custom_fields.created_at,
               sample_custom_fields.updated_at
        FROM custom_fields
        INNER JOIN sample_custom_fields
        ON custom_fields.id = sample_custom_fields.custom_field_id
        WHERE sample_custom_fields.sample_id = #{sample_id}
      SQL
      ActiveRecord::Base.connection.execute(custom_sample_fields_sql).to_a
    end

    def self.get_assigned_sample_module(sample_id)
      assigned_samples_sql = <<-SQL
        SELECT my_module_id, assigned_by_id
        FROM sample_my_modules
        WHERE sample_my_modules.sample_id = #{sample_id}
      SQL
      ActiveRecord::Base.connection.execute(assigned_samples_sql).to_a
    end

    def self.fetch_all_team_samples(team)
      samples_sql = <<-SQL
        SELECT samples.id AS sample_id,
               samples.name AS sample_name,
               samples.user_id AS sample_created_by_id,
               samples.last_modified_by_id AS sample_last_modified_by_id,
               samples.created_at AS sample_created_at,
               samples.updated_at AS sample_updated_at,
               sample_types.name AS sample_type_name,
               sample_groups.name AS sample_group_name,
               sample_groups.color AS sample_group_color
        FROM samples
        LEFT OUTER JOIN sample_types
        ON samples.sample_type_id = sample_types.id
        LEFT OUTER JOIN sample_groups
        ON samples.sample_group_id = sample_groups.id
        WHERE samples.team_id = #{team.id}
        ORDER BY samples.id
      SQL

      ActiveRecord::Base.connection.execute(samples_sql).to_a
    end

    def self.get_custom_columns(team, repository)
      prepare_text_value_custom_columns(team, repository) +
        prepare_list_value_custom_columns_with_list_items(team, repository)
    end

    def self.create_text_cell(row_id, column_id, data,
                              created_by_id, last_modified_by_id)
      conn = ActiveRecord::Base.connection
      timestamp = conn.quote(Time.now.to_s(:db))
      values = [conn.quote(data), created_by_id, last_modified_by_id, timestamp, timestamp]
      value_sql = <<-SQL
        INSERT INTO repository_text_values
          (data, created_by_id, last_modified_by_id,
           created_at, updated_at)
        VALUES (#{values.join(', ')})
        RETURNING id
      SQL

      value_id = conn.execute(value_sql)[0]['id']

      values = [row_id, column_id, value_id, conn.quote('RepositoryTextValue'),
                timestamp, timestamp]
      cell_sql = <<-SQL
        INSERT INTO repository_cells
          (repository_row_id, repository_column_id, value_id, value_type,
           created_at, updated_at)
        VALUES (#{values.join(', ')})
      SQL
      conn.execute(cell_sql)
    end

    def self.create_list_cell(row_id, column_id, list_item_id,
                              created_by_id, last_modified_by_id)
      conn = ActiveRecord::Base.connection
      timestamp = conn.quote(Time.now.to_s(:db))
      values = [list_item_id, created_by_id, last_modified_by_id,
                timestamp, timestamp]
      list_value_sql = <<-SQL
        INSERT INTO repository_list_values
          (repository_list_item_id, created_by_id, last_modified_by_id,
           created_at, updated_at)
        VALUES (#{values.join(', ')})
        RETURNING id
      SQL
      value_id = ActiveRecord::Base.connection.execute(list_value_sql)[0]['id']

      values = [row_id, column_id, value_id, conn.quote('RepositoryListValue'),
                timestamp, timestamp]
      cell_sql = <<-SQL
        INSERT INTO repository_cells
          (repository_row_id, repository_column_id, value_id, value_type,
           created_at, updated_at)
        VALUES (#{values.join(', ')})
      SQL
      ActiveRecord::Base.connection.execute(cell_sql)
    end

    def self.update_smart_annotations(team, mappings)
      team.projects.eager_load(:project_comments).each do |pr|
        pr.project_comments.each do |comment|
          comment.save! if update_annotation(comment.message, mappings)
        end
        pr.experiments.each do |exp|
          exp.save! if update_annotation(exp.description, mappings)
          exp.my_modules.eager_load(:task_comments).each do |task|
            task.task_comments.each do |comment|
              comment.save! if update_annotation(comment.message, mappings)
            end
            task.save! if update_annotation(task.description, mappings)
            task.protocol.steps.eager_load(:step_comments).each do |step|
              step.step_comments.each do |comment|
                comment.save! if update_annotation(comment.message, mappings)
              end
              step.save! if update_annotation(step.description, mappings)
            end
            task.results.eager_load(:result_comments, :result_text).each do |res|
              res.result_comments.each do |comment|
                comment.save! if update_annotation(comment.message, mappings)
              end
              next unless res.result_text
              res.save! if update_annotation(res.result_text.text, mappings)
            end
          end
        end
      end
      team.protocols.where(my_module: nil).each do |protocol|
        protocol.steps.eager_load(:step_comments).each do |step|
          step.step_comments.each do |comment|
            comment.save! if update_annotation(comment.message, mappings)
          end
          step.save! if update_annotation(step.description, mappings)
        end
      end
      team.repositories.each do |rep|
        rep.repository_rows.includes(repository_cells: :repository_text_value)
           .where('repository_cells.value_type': 'RepositoryTextValue')
           .each do |row|
          row.repository_cells.each do |cell|
            if update_annotation(cell.repository_text_value.data, mappings)
              cell.repository_text_value.save!
            end
          end
        end
      end
    end

    # Returns true if text was updated
    def self.update_annotation(text, sample_mappings)
      return false if text.nil?
      updated = false
      text.scan(/~sam~\w+\]/).each do |text_match|
        orig_id_encoded = text_match.match(/~sam~(\w+)\]/)[1]
        orig_id = orig_id_encoded.base62_decode
        next unless sample_mappings[orig_id]
        new_id_encoded = sample_mappings[orig_id].base62_encode
        text.sub!("~sam~#{orig_id_encoded}]", "~rep_item~#{new_id_encoded}]")
        updated = true
      end
      updated
    end
  end
end
