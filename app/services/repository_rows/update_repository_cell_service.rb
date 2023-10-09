# frozen_string_literal: true

module RepositoryRows
  class UpdateRepositoryCellService
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

      # rubocop:disable Metrics/BlockLength
      @repository_row.with_lock do
        if @params.dig(:repository_row, :name)
          # Update inventory row name when name params is present
          @repository_row.name = @params[:repository_row][:name]

          if @repository_row.changed?
            @repository_row.last_modified_by = @user
            @repository_row.save!
            @record_updated = true
          end
        elsif @params[:repository_cell]
          column =
            @repository_row.repository
                           .repository_columns
                           .find_by(id: @params[:repository_cell][:column_id])
          return self unless column

          value = @params[:repository_cell][:value]
          cell = column.repository_cells.find_by(repository_column_id: column.id)
          # Update invetory row's cell
          if cell.present? && value.blank?
            cell.destroy!
            @record_updated = true
          elsif cell.blank? && value.present?
            RepositoryCell.create_with_value!(@repository_row, column, value, @user)
            @record_updated = true
          elsif cell.value.data_different?(value)
            cell.value.update_data!(value, @user)
            @record_updated = true
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[e.record.class.name.underscore] = e.record.errors.full_messages
        @record_updated = false
      end
      # rubocop:enable Metrics/BlockLength
      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      # check that repository cell data is in params
      if @params[:repository_cell] && !@params[:repository_cell].key?(:value)
        @errors[:invalid_arguments] =
          I18n.t('repositories.multiple_share_service.invalid_arguments', key: 'Params')
        return false
      end

      unless @user && @repository_row && @params
        @errors[:invalid_arguments] =
        { 
          repository_row:,
          params: @params,
          user:
        }.map do |key, value|
            I18n.t('repositories.multiple_share_service.invalid_arguments', key: key.capitalize) if value.nil?
        end.compact!
        return false
      end
      true
    end
  end
end
