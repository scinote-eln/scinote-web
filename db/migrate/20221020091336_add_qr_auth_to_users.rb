class AddQrAuthToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :qr_auth_code, :string  
  end
end
