class UpdateValuesInMyModuleStatuses < ActiveRecord::Migration[7.0]
  def up
    MyModuleStatus.where(name: 'Not started').update_all(color: '#FFFFFF')
    MyModuleStatus.where(name: 'In progress').update_all(color: '#3070ED')
    MyModuleStatus.where(name: 'Completed').update_all(color: '#5EC66F')
    MyModuleStatus.where(name: 'In review').update_all(color: '#E9A845')
    MyModuleStatus.where(name: 'Done').update_all(color: '#6F2DC1')
  end

  def down
    MyModuleStatus.where(name: 'Not started').update_all(color: '#406d86')
    MyModuleStatus.where(name: 'In progress').update_all(color: '#0065ff')
    MyModuleStatus.where(name: 'Completed').update_all(color: '#00b900')
    MyModuleStatus.where(name: 'In review').update_all(color: '#ff4500')
    MyModuleStatus.where(name: 'Done').update_all(color: '#0ecdc0')
  end
end
