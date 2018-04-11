# frozen_string_literal: true

require 'repository_actions/repository_cell_resolver'

module RepositoryActions
  class Duplicate
    attr_reader :number_of_duplicated_items
    def initialize(user, repository, rows_to_copy = [])
      @user                       = user
      @repository                 = repository
      @rows_to_copy               = rows_to_copy.map(&:to_i).uniq
      @number_of_duplicated_items = 0
    end

    def call
      sanitize_rows_to_copy
      @rows_to_copy.each do |row_id|
        copy_row(row_id)
      end
    end

    private

    def sanitize_rows_to_copy
      ids = @repository.repository_rows.pluck(:id)
      @rows_to_copy.map! { |el| ids.include?(el) ? el : nil }.compact!
    end

    def copy_row(id)
      row = RepositoryRow.find_by_id(id)
      new_row = RepositoryRow.new(
        row.attributes.merge(new_row_attributes(row.name))
      )

      if new_row.save
        @number_of_duplicated_items += 1
        row.repository_cells.each do |cell|
          copy_repository_cell(cell, new_row)
        end
      end
    end

    def new_row_attributes(name)
      timestamp = DateTime.now
      { id: nil,
        name: "#{name} (1)",
        created_at: timestamp,
        updated_at: timestamp }
    end

    def copy_repository_cell(cell, new_row)
      RepositoryActions::RepositoryCellResolver.new(cell,
                                                    new_row,
                                                    @user.current_team).call
    end
  end
end
