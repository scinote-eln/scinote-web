# frozen_string_literal: true

class AddReadOnlyDescriptions < ActiveRecord::Migration[7.2]
  include DatabaseHelper

  def change
    add_column :projects, :read_only_description, :text
    add_gin_index_without_tags :projects, :read_only_description

    add_column :experiments, :read_only_description, :text
    add_gin_index_without_tags :experiments, :read_only_description

    add_column :my_modules, :read_only_description, :text
    add_gin_index_without_tags :my_modules, :read_only_description
  end
end
