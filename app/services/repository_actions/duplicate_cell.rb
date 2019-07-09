# frozen_string_literal: true

module RepositoryActions
  class DuplicateCell
    def initialize(cell, new_row, user, team)
      @cell    = cell
      @new_row = new_row
      @user    = user
      @team    = team
    end

    def call
      self.send("duplicate_#{@cell.value_type.underscore}")
    end

    private

    def duplicate_repository_list_value
      old_value = @cell.value
      RepositoryListValue.create(
        old_value.attributes.merge(
          id: nil, created_by: @user, last_modified_by: @user,
          repository_cell_attributes: {
            repository_row: @new_row,
            repository_column: @cell.repository_column
          }
        )
      )
    end

    def duplicate_repository_text_value
      old_value = @cell.value
      RepositoryTextValue.create(
        old_value.attributes.merge(
          id: nil, created_by: @user, last_modified_by: @user,
          repository_cell_attributes: {
            repository_row: @new_row,
            repository_column: @cell.repository_column
          }
        )
      )
    end

    def duplicate_repository_asset_value
      old_value = @cell.value
      new_asset = old_value.asset.duplicate
      RepositoryAssetValue.create(
        old_value.attributes.merge(
          id: nil, asset: new_asset, created_by: @user, last_modified_by: @user,
          repository_cell_attributes: {
            repository_row: @new_row,
            repository_column: @cell.repository_column
          }
        )
      )
    end

    def duplicate_repository_date_value
      old_value = @cell.value
      RepositoryDateValue.create(
        old_value.attributes.merge(
          id: nil, created_by: @user, last_modified_by: @user,
          repository_cell_attributes: {
            repository_row: @new_row,
            repository_column: @cell.repository_column
          }
        )
      )
    end
  end
end
