class AddCurrentOrganizationToUser < ActiveRecord::Migration
  def up
    add_column :users, :current_organization_id, :integer
    add_foreign_key :users, :organizations, column: :current_organization_id

    User.find_each do |user|
      user.update(current_organization_id: user.organizations.first.id)
    end
  end

  def down
    remove_column :users, :current_organization_id
  end
end
