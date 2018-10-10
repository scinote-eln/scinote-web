# frozen_string_literal:true

class CreateViewStates < ActiveRecord::Migration[5.1]
  def change
    create_table :view_states do |t|
      t.jsonb :state
      t.references :user, foreign_key: true
      t.references :viewable, polymorphic: true

      t.timestamps
    end
  end
end
