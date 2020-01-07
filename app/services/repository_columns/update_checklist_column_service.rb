# frozen_string_literal: true

module RepositoryColumns
  class UpdateChecklistColumnService < RepositoryColumns::ColumnService
    def initialize(user:, team:, column:, params:)
      super(user: user, repository: column.repository, team: team, column_name: nil)
      @column = column
      @params = params
    end

    def call
      return self unless valid?

      @column.lock!

      updating_items_names = @params[:repository_checklist_items_attributes].to_a.map { |e| e[:data] }
      existing_items_names = @column.repository_checklist_items.pluck(:data)
      to_be_deleted = existing_items_names - updating_items_names
      to_be_created = updating_items_names - existing_items_names

      if @column.repository_list_items.size - to_be_deleted.size + to_be_created.size >=
         Constants::REPOSITORY_CHECKLIST_ITEMS_PER_COLUMN

        @errors[:repository_column] = { repository_checklist_items: 'too many items' }
      end
      return self unless valid?

      @errors[:repository_column] = @column.errors.messages unless @column.update(@params.slice(:name, :metadata))
      return self unless valid?

      ActiveRecord::Base.transaction do
        to_be_deleted.each do |item|
          @column.repository_checklist_items.find_by(data: item).destroy!.id
        end

        to_be_created.each do |item|
          RepositoryChecklistItem.create!(
            repository: @repository,
            repository_column: @column,
            data: item,
            created_by: @user,
            last_modified_by: @user
          )
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[:repository_column] = { repository_checklist_item: e.message }

        raise ActiveRecord::Rollback
      end
      log_activity(:edit_column_inventory) if valid?

      self
    end
  end
end
