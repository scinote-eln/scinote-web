# frozen_string_literal: true

class ConvertToActiveStorage < ActiveRecord::Migration[5.2]
  def up
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
