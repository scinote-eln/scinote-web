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
      new_asset = create_new_asset(old_value.asset)
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

    # reuses the same code we have in copy protocols action
    def create_new_asset(old_asset)
      new_asset = Asset.new_empty(
        old_asset.file_file_name,
        old_asset.file_file_size
      )
      new_asset.created_by = old_asset.created_by
      new_asset.team = @team
      new_asset.last_modified_by = @user
      new_asset.file_processing = true if old_asset.is_image?
      new_asset.file = old_asset.file
      new_asset.save

      return unless new_asset.valid?

      if new_asset.is_image?
        new_asset.file.reprocess!(:large)
        new_asset.file.reprocess!(:medium)
      end

      new_asset.post_process_file(new_asset.team)

      new_asset
    end
  end
end
