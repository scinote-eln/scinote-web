# frozen_string_literal: true

module RepositoryActions
  class DuplicateCell
    def initialize(cell, new_row, user)
      @cell    = cell
      @new_row = new_row
      @user    = user
    end

    def call
      new_value = @cell.value.dup
      new_cell = RepositoryCell.new(repository_row: @new_row, repository_column: @cell.repository_column)

      new_cell.value = new_value
      new_value.created_by = @user
      new_value.last_modified_by = @user

      if respond_to?("#{@cell.value_type.split('::').last.underscore}_extra_attributes", true)
        __send__("#{@cell.value_type.split('::').last.underscore}_extra_attributes", new_value)
      end
      new_value.save!
    end

    private

    def repository_asset_value_extra_attributes(value)
      new_asset = @cell.value.asset.duplicate
      value.asset = new_asset
    end

    def repository_checklist_value_extra_attributes(value)
      value.repository_checklist_items = @cell.value.repository_checklist_items
    end
  end
end
