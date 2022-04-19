# frozen_string_literal: true

module RepositoryColumns
  class CreateColumnService < RepositoryColumns::ColumnService
    def initialize(user:, repository:, params:, team:, column_type:)
      super(user: user, repository: repository, team: team, column_name: params[:name])
      @column_type = column_type
      @params = params
    end

    def call
      return self unless valid?

      @column = RepositoryColumn.new(column_attributes)

      if @column.save
        log_activity(:create_column_inventory)
      else
        errors[:repository_column] = @column.errors.messages
      end

      self
    end

    private

    def column_attributes
      @params[:repository_status_items_attributes]&.map do |m|
        m.merge!(created_by_id: @user.id, last_modified_by_id: @user.id)
      end

      @params[:repository_list_items_attributes]&.map do |m|
        m.merge!(created_by_id: @user.id, last_modified_by_id: @user.id)
      end

      @params[:repository_checklist_items_attributes]&.map do |m|
        m.merge!(created_by_id: @user.id, last_modified_by_id: @user.id)
      end

      @params[:repository_stock_unit_items_attributes]&.map do |m|
        m.merge!(created_by_id: @user.id, last_modified_by_id: @user.id)
      end

      @params.merge(repository_id: @repository.id, created_by_id: @user.id, data_type: @column_type)
    end
  end
end
