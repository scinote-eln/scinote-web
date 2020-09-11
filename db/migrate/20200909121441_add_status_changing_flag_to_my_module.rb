# frozen_string_literal: true

class AddStatusChangingFlagToMyModule < ActiveRecord::Migration[6.0]
  def change
    change_table :my_modules do |t|
      t.boolean :status_changing, default: false
      t.references :changing_from_my_module_status, foreign_key: { to_table: :my_module_statuses }, index: false
    end
  end
end
