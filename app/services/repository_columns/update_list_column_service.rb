# frozen_string_literal: true

module RepositoryColumns
  class UpdateListColumnService < RepositoryColumns::ColumnService
    def initialize(user:, team:, column:, params:)
      super(user: user, repository: column.repository, team: team, column_name: nil)
      @column = column
      @params = params
    end

    def call
      return self unless valid?

      @column.lock!

      updating_items_names = @params[:repository_list_items_attributes].to_a.map { |e| e[:data] }
      existing_items_names = @column.repository_list_items.pluck(:data)
      to_be_deleted = existing_items_names - updating_items_names
      to_be_created = updating_items_names - existing_items_names

      if @column.repository_list_items.size - to_be_deleted.size + to_be_created.size >=
         Constants::REPOSITORY_LIST_ITEMS_PER_COLUMN

        @errors[:repository_column] = { repository_list_items: 'too many items' }
      end
      return self unless valid?

      @errors[:repository_column] = @column.errors.messages unless @column.update(@params.slice(:name, :metadata))
      return self unless valid?

      ActiveRecord::Base.transaction do
        to_be_deleted.each do |item|
          @column.repository_list_items.find_by(data: item).destroy!
        end

        to_be_created.each do |item|
          RepositoryListItem.create!(
            repository: @repository,
            repository_column: @column,
            data: item,
            created_by: @user,
            last_modified_by: @user
          )
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[:repository_column] = { repository_list_item: e.message }

        raise ActiveRecord::Rollback
      end
      log_activity(:edit_column_inventory) if valid?

      self
    end
  end
end
