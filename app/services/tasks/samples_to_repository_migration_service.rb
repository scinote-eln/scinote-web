# Helper module for dealing with the migration from samples
# to custom repositories. We need to query with SQL because probably we will not
# have the "Sample" and other related models at the time this code will execute

module Tasks
  module SamplesToRepositoryMigrationService
    def self.prepare_repository(team, copy_num = 0)
      repository = Repository.new(
        name: copy_num > 0 ? "Samples (#{copy_num})" : 'Samples',
        team: team,
        created_by: team.created_by
      )
      return repository if repository.save
      prepare_repository(team, copy_num += 1)
    end

    def self.prepare_text_value_custom_columns(team, repository)
      custom_columns_sql = <<-SQL
        SELECT * FROM custom_fields WHERE team_id = #{team.id}
      SQL
      # execute query
      custom_columns = ActiveRecord::Base.connection.execute(custom_columns_sql)

      repository_columns = []
      custom_columns.each_with_index do |column, index|
        repository_column = RepositoryColumn.create(
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
      sample_types = ActiveRecord::Base.connection.execute(sample_types_sql)
      sample_groups = ActiveRecord::Base.connection.execute(sample_groups_sql)

      repository_columns = []

      repository_columns << RepositoryColumn.create(
        repository: repository,
        created_by_id: repository.created_by_id,
        data_type: :RepositoryListValue,
        name: 'Sample group'
      )

      repository_columns << RepositoryColumn.create(
        repository: repository,
        created_by_id: repository.created_by_id,
        data_type: :RepositoryListValue,
        name: 'Sample type'
      )

      sample_groups.each_with_index do |item, index|
        RepositoryListItem.create(
          data: item.fetch('name') { "sample group item (#{index})" },
          created_by_id: item.fetch('created_by_id') { team.created_by_id },
          last_modified_by_id:
            item.fetch('last_modified_by_id') { team.created_by_id },
          repository_column: repository_columns.first,
          repository: repository
        )
      end

      sample_types.each_with_index do |item, index|
        RepositoryListItem.create(
          data: item.fetch('name') { "sample group item (#{index})" },
          created_by_id: item.fetch('created_by_id') { team.created_by_id },
          last_modified_by_id:
            item.fetch('last_modified_by_id') { team.created_by_id },
          repository_column: repository_columns.last,
          repository: repository
        )
      end

      repository_columns
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
        SELECT my_module_id, assigned_by_id, assigned_on
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
               sample_types.name AS sample_type_name,
               sample_groups.name AS sample_group_name,
               sample_groups.color AS sample_group_color
        FROM samples
        JOIN sample_types ON samples.sample_type_id = sample_types.id
        JOIN sample_groups ON samples.sample_type_id = sample_groups.id
        WHERE samples.team_id = #{team.id}
      SQL

      ActiveRecord::Base.connection.execute(samples_sql).to_a
    end
  end
end
