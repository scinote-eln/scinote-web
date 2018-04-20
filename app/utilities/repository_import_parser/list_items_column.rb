module RepositoryImportParser
  class ListItemsColumn
    attr_accessor :column, :list_items_number

    def initialize(column, list_items_number)
      @column = column
      @list_items_number = list_items_number
    end

    def has_column?(column)
      @column == column
    end
  end
end
