# frozen_string_literal: true

module RepositoryColumns
  class UpdateStockColumnService < RepositoryColumns::ColumnService
    def initialize(user:, team:, column:, params:)
      super(user: user, repository: column.repository, team: team, column_name: nil)
      @column = column
      @params = params
    end

    def call
      return self unless valid?

      @column.lock!

      updating_units_names = @params[:repository_stock_unit_items_attributes].to_a.pluck(:data)
      existing_units_names = @column.repository_stock_unit_items.pluck(:data)
      to_be_deleted = existing_units_names - updating_units_names
      to_be_created = updating_units_names - existing_units_names

      if @column.repository_stock_unit_items.size - to_be_deleted.size + to_be_created.size >
         Constants::REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN

        @errors[:repository_column] = { repository_stock_unit_items: 'too many items' }
      end
      return self unless valid?

      @errors[:repository_column] = @column.errors.messages unless @column.update(@params.slice(:name, :metadata))
      return self unless valid?

      ActiveRecord::Base.transaction do
        to_be_deleted.each do |item|
          @column.repository_stock_unit_items.find_by(data: item).destroy!.id
        end

        to_be_created.each do |item|
          RepositoryStockUnitItem.create!(
            repository_column: @column,
            data: item,
            created_by: @user,
            last_modified_by: @user
          )
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors[:repository_column] = { repository_stock_unit_item: e.message }

        raise ActiveRecord::Rollback
      end
      log_activity(:edit_column_inventory) if valid?

      self
    end
  end
end
