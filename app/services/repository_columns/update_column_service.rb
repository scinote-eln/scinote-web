# frozen_string_literal: true

module RepositoryColumns
  class UpdateColumnService < RepositoryColumns::ColumnService
    def initialize(user:, team:, column:, params:)
      super(user: user, repository: column.repository, team: team, column_name: nil)
      @column = column
      @params = params
    end

    def call
      return self unless valid?

      if @column.update(column_attributes)
        log_activity(:edit_column_inventory)
      else
        errors[:repository_column] = @column.errors.messages
      end

      self
    end

    private

    def column_attributes
      @params[:repository_status_items_attributes]&.map do |m|
        # assign for new records only
        m.merge!(repository_id: @repository.id, created_by_id: @user.id, last_modified_by_id: @user.id) unless m[:id]
      end

      @params
    end
  end
end
