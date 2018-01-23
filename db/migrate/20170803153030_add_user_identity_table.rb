class AddUserIdentityTable < ActiveRecord::Migration[4.2]
  def change
    create_table :user_identities do |t|
      t.belongs_to :user, index: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.timestamps null: true
    end

    add_index :user_identities, %i(provider uid), unique: true
    add_index :user_identities, %i(user_id provider), unique: true
  end
end
