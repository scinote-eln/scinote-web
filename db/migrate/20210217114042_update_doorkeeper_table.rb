class UpdateDoorkeeperTable < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        change_column :oauth_access_grants, :scopes, :string, null: false, default: ''
      end
      dir.down do
        change_column :oauth_access_grants, :scopes, :string
      end
    end
  end
end
