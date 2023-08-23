# frozen_string_literal: true

# rubocop:disable Rails/SkipsModelValidations
class UpdateValuesInMyModuleStatuses < ActiveRecord::Migration[7.0]
  def up
    MyModuleStatus.where(name: 'Not started').update_all(color: '#FFFFFF')
    MyModuleStatus.where(name: 'In progress').update_all(color: '#3070ED')
    MyModuleStatus.where(name: 'Completed').update_all(color: '#5EC66F')
  end

  def down
    MyModuleStatus.where(name: 'Not started').update_all(color: '#406d86')
    MyModuleStatus.where(name: 'In progress').update_all(color: '#0065ff')
    MyModuleStatus.where(name: 'Completed').update_all(color: '#00b900')
  end
end
# rubocop:enable Rails/SkipsModelValidations
