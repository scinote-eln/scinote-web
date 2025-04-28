# frozen_string_literal: true

class CreateFavorites < ActiveRecord::Migration[7.0]
  def change
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :item, polymorphic: true, null: false

      t.timestamps
    end

    add_index(
      :favorites,
      %i(user_id team_id item_id item_type),
      unique: true,
      name: :index_favorites_on_user_and_item_and_team
    )
  end
end
