# frozen_string_literal: true

class RemoveTagDefaultColor < ActiveRecord::Migration[7.2]
  def change
    change_column_default :tags, :color, from: '#ff0000', to: nil
  end
end
