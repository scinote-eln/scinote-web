# frozen_string_literal: true

class AddSearchIndexToActivities < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :search_index, :string
  end
end
