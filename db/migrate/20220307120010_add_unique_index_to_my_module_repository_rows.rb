# frozen_string_literal: true

class AddUniqueIndexToMyModuleRepositoryRows < ActiveRecord::Migration[6.1]
  def change
    remove_index :my_module_repository_rows,
                 %i(my_module_id repository_row_id),
                 name: 'index_my_module_ids_repository_row_ids'
    add_index :my_module_repository_rows,
              %i(my_module_id repository_row_id),
              name: 'index_my_module_ids_repository_row_ids',
              unique: true
  end
end
