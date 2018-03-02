# frozen_string_literal: true

# this class is used to resolve the column data_type and assign
# it to the repository_row
module RepositoryImportParser
  class RepositoryCellValueResolver

    def initialize(column, user, repository)
      @column = column
      @user = user
      @repository = repository
    end

    def get_value(value, record_row)
      return unless @column
      send("new_#{@column.data_type.underscore}", value, record_row)
    end

    private

    def new_repository_text_value(value, record_row)
      RepositoryTextValue.new(data: value,
                              created_by: @user,
                              last_modified_by: @user,
                              repository_cell_attributes: {
                                repository_row: record_row,
                                repository_column: @column
                              })
    end

    def new_repository_list_value(value, record_row)
      list_item = @column.repository_list_items.find_by_data(value)
      list_item ||= create_repository_list_item(value)
      RepositoryListValue.new(
        created_by: @user,
        last_modified_by: @user,
        repository_list_item: list_item,
        repository_cell_attributes: {
          repository_row: record_row,
          repository_column: @column
        }
      )
    end

    def create_repository_list_item(value)
      RepositoryListItem.create(
        data: value,
        created_by: @user,
        last_modified_by: @user,
        repository_column: @column,
        repository: @repository
      )
    end
  end
end
