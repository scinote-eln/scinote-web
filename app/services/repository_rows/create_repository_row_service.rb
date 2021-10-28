# frozen_string_literal: true

module RepositoryRows
  class CreateRepositoryRowService
    extend Service

    attr_reader :repository, :params, :errors, :repository_row

    def initialize(repository:, user:, params:)
      @repository = repository
      @user = user
      @params = params
      @errors = {}
      @repository_row = nil
    end

    def call
      return self unless valid?

      ActiveRecord::Base.transaction do
        @repository_row = @repository.repository_rows.new(params[:repository_row])
        @repository_row.last_modified_by = @user
        @repository_row.created_by = @user
        @repository_row.save!

        params[:repository_cells]&.each do |column_id, value|
          column = @repository.repository_columns.find_by(id: column_id)
          next if !column || value.blank?

          RepositoryCell.create_with_value!(@repository_row, column, value, @user)
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[e.record.class.name.underscore] = e.record.errors.full_messages
        raise ActiveRecord::Rollback
      end

      self
    end

    def succeed?
      @errors.none?
    end

    private

    def valid?
      unless @user && @repository && @params
        @errors[:invalid_arguments] =
          { 'repository': @repository,
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
