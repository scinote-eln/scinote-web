# frozen_string_literal: true

module RepositoryRows
  class UpdateRepositoryRowService
    extend Service

    attr_reader :repository_row, :params, :errors, :record_updated

    def initialize(repository_row:, user:, params:)
      @repository_row = repository_row
      @user = user
      @params = params
      @record_updated = false
      @errors = {}
    end

    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        # Update invetory row's cells
        params[:repository_cells]&.each do |column_id, value|
          column = @repository_row.repository.repository_columns.find_by(id: column_id)
          next unless column

          cell = @repository_row.repository_cells.find_by(repository_column_id: column.id)

          if cell.present? && value.blank?
            cell.destroy!
            @record_updated = true
            next
          elsif cell.blank? && value.present?
            RepositoryCell.create_with_value!(@repository_row, column, value, @user)
            @record_updated = true
            next
          elsif cell.blank? && value.blank?
            next
          end

          if cell.value.data_changed?(value)
            cell.value.update_data!(value, @user)
            @record_updated = true
          end
        end

        # Update invetory rows
        @repository_row.attributes = params[:repository_row]

        if @repository_row.changed?
          @repository_row.last_modified_by = @user
          @repository_row.save!
          @record_updated = true
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[e.record.class.name.underscore] = e.record.errors.full_messages
        @record_updated = false
        raise ActiveRecord::Rollback
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless @user && @repository_row && @params
        @errors[:invalid_arguments] =
          { 'repository_row': @repository_row,
            'params': @params,
            'user': @user }
          .map do |key, value|
            I18n.t('repositories.multiple_share_service.invalid_arguments', key: key.capitalize) if value.nil?
          end.compact
        return false
      end
      true
    end
  end
end
