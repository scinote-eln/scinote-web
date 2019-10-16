# frozen_string_literal: true

module RepositoryColumns
  class CreateListColumnService < RepositoryColumns::ColumnService
    def initialize(user:, repository:, params:, team:)
      super(user: user, repository: repository, team: team, column_name: params[:name])
      @params = params
    end

    def call
      return self unless valid?

      @column = RepositoryColumn.new(repository_list_items_attributes)

      if @column.save
        log_activity(:create_column_inventory)
      else
        errors[:repository_column] = @column.errors.messages
      end

      self
    end

    private

    def repository_list_items_attributes
      @params[:repository_list_items_attributes]&.map do |m|
        m.merge!(repository_id: @repository.id, created_by_id: @user.id, last_modified_by_id: @user.id)
      end
      @params.merge(repository_id: @repository.id, created_by_id: @user.id, data_type: :RepositoryListValue)
    end
  end
end
