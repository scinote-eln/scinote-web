# frozen_string_literal: true

class AddUniquenessLookupIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :repository_rows, 'repository_id, LOWER(name)',
              name: 'index_repository_rows_on_repository_id_and_lower_name'

    add_index :repository_text_values, 'LOWER(data)',
              name: 'index_repository_text_values_on_lower_data',
              using: :hash
  end
end
