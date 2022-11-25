# frozen_string_literal: true

class AddProvisioningStatusToMyModules < ActiveRecord::Migration[6.1]
  def change
    add_column :my_modules, :provisioning_status, :integer
  end
end
