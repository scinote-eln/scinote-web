# frozen_string_literal: true

module RepositoryRows
  class DuplicatesScanService
    WHITESPACE = " \t\n\r\f\v"
    TEXT_VALUES_JOIN = <<~SQL.squish
      INNER JOIN repository_text_values
        ON repository_text_values.id = repository_cells.value_id
        AND repository_cells.value_type = 'RepositoryTextValue'
    SQL

    def initialize(repository)
      @repository = repository
    end

    def call
      return [] unless @repository.is_a?(Repository)

      ids = @repository.enforce_unique_item_names? ? name_duplicate_row_ids : []
      unique_text_columns.each { |column| ids.concat(text_duplicate_row_ids(column)) }
      ids.uniq
    end

    def duplicates_of(row)
      return [] unless @repository.is_a?(Repository)

      ids = []
      if @repository.enforce_unique_item_names?
        ids.concat(ids_with_same_value(@repository.repository_rows.active, 'repository_rows.name', row.name,
                                       @repository.unique_item_names_case_sensitive?))
      end
      unique_text_columns.each do |column|
        value = row.repository_cells.find_by(repository_column_id: column.id)&.value
        next unless value.is_a?(RepositoryTextValue)

        rows = RepositoryRow.active
                            .joins(:repository_cells)
                            .joins(TEXT_VALUES_JOIN)
                            .where(repository_rows: { repository_id: @repository.id })
                            .where(repository_cells: { repository_column_id: column.id })
        ids.concat(ids_with_same_value(rows, 'repository_text_values.data', value.data, column.unique_case_sensitive?))
      end
      ids.uniq - [row.id]
    end

    private

    def unique_text_columns
      @repository.repository_columns
                 .where(data_type: Extends::REPOSITORY_DATA_TYPES[:RepositoryTextValue])
                 .select(&:enforce_unique?)
    end

    def name_duplicate_row_ids
      key = match_key('repository_rows.name', @repository.unique_item_names_case_sensitive?)
      rows = @repository.repository_rows.active.select(:id, "#{key} AS match_key")
      duplicated_ids(rows)
    end

    def text_duplicate_row_ids(column)
      key = match_key('repository_text_values.data', column.unique_case_sensitive?)
      rows = RepositoryRow.active
                          .joins(:repository_cells)
                          .joins(TEXT_VALUES_JOIN)
                          .where(repository_rows: { repository_id: @repository.id })
                          .where(repository_cells: { repository_column_id: column.id })
                          .select(:id, "#{key} AS match_key")
      duplicated_ids(rows)
    end

    def ids_with_same_value(rows, column_sql, value, case_sensitive)
      value_key = match_key(RepositoryRow.connection.quote(value.to_s), case_sensitive)
      rows.where("#{match_key(column_sql, case_sensitive)} = #{value_key} AND #{value_key} <> ''").distinct.pluck(:id)
    end

    def match_key(column_sql, case_sensitive)
      trimmed = ActiveRecord::Base.sanitize_sql_array(["BTRIM(#{column_sql}, ?)", WHITESPACE])
      case_sensitive ? trimmed : "LOWER(#{trimmed})"
    end

    def duplicated_ids(rows)
      RepositoryRow.connection.select_values(<<~SQL.squish).map(&:to_i)
        SELECT id FROM (
          SELECT id, COUNT(*) OVER (PARTITION BY match_key) AS group_size
          FROM (#{rows.to_sql}) AS values_to_match
          WHERE match_key <> ''
        ) AS grouped
        WHERE group_size > 1
      SQL
    end
  end
end
