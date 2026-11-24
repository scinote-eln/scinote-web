module RepositoryRows
  class DuplicateValidationService
    DUPLICATE_NAME_SUFFIX = ' (1)'

    def self.duplicate_name(name)
      "#{name}#{DUPLICATE_NAME_SUFFIX}"
    end

    def initialize(repository, repository_rows)
      @repository = repository
      @repository_rows = repository_rows.to_a
      @row_ids = @repository_rows.map(&:id)
    end

    def error
      return :mandatory if mandatory_cells_missing?
      return :unique if unique_values_broken?

      nil
    end

    def unique_errors
      errors = {}
      name_message = I18n.t('activerecord.errors.models.repository_row.attributes.name.not_unique')
      errors[:name] = [name_message] if duplicate_names_taken?

      value_message = I18n.t('activerecord.errors.models.repository_text_value.attributes.data.not_unique')
      unique_cells = filled_unique_column_ids.index_with { [value_message] }
      errors[:unique_cells] = unique_cells if unique_cells.any?
      errors
    end

    def mandatory_cells_missing?
      mandatory_column_ids = @repository.repository_columns.where(mandatory: true).pluck(:id)
      return false if mandatory_column_ids.empty?

      filled_counts = RepositoryCell.where(repository_row_id: @row_ids, repository_column_id: mandatory_column_ids)
                                    .group(:repository_row_id)
                                    .count
      @row_ids.any? { |row_id| filled_counts[row_id].to_i < mandatory_column_ids.size }
    end

    def unique_values_broken?
      duplicate_names_taken? || filled_unique_column_ids.any?
    end

    private

    def duplicate_names_taken?
      return false unless @repository.is_a?(Repository) && @repository.enforce_unique_item_names?

      names = @repository_rows.map { |row| self.class.duplicate_name(row.name).strip.downcase }
      return true if names.uniq.size != names.size

      @repository.repository_rows.exists?(['LOWER(repository_rows.name) IN (?)', names])
    end

    def filled_unique_column_ids
      @filled_unique_column_ids ||= begin
        unique_column_ids = @repository.repository_columns
                                       .where(data_type: :RepositoryTextValue)
                                       .select(&:enforce_unique?)
                                       .map(&:id)
        if unique_column_ids.empty?
          []
        else
          RepositoryCell.where(repository_row_id: @row_ids, repository_column_id: unique_column_ids)
                        .distinct
                        .pluck(:repository_column_id)
        end
      end
    end
  end
end
