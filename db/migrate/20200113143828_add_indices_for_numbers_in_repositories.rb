# frozen_string_literal: true

require File.expand_path('app/helpers/database_helper')

class AddIndicesForNumbersInRepositories < ActiveRecord::Migration[6.0]
  include DatabaseHelper

  def up
    add_gin_index_for_numbers :repository_rows, :id
    add_gin_index_for_numbers :repository_number_values, :data
  end

  def down
    remove_gin_index_for_numbers :repository_rows, :id
    remove_gin_index_for_numbers :repository_number_values, :data
  end
end
