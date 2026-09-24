# frozen_string_literal: true

class AddAvatarColorToUsers < ActiveRecord::Migration[7.2]
  def up
    add_column :users, :avatar_color, :string, limit: 7

    execute <<~SQL.squish
      UPDATE users
      SET avatar_color = (ARRAY[
        '#C4D3A0', '#5EC66F', '#46C3C8', '#A3CCE4', '#3B99FD', '#104DA9', '#6F2DC1', '#FF69B4',
        '#DF3562', '#FF5C00', '#E9A845', '#B06500', '#663300', '#1D2939', '#98A2B3', '#DCE0E7'
      ])[floor(random() * 16)::int + 1]
      WHERE avatar_color IS NULL;
    SQL

    change_column_null :users, :avatar_color, false
  end

  def down
    remove_column :users, :avatar_color
  end
end
