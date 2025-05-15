class UpdateMyModuleCoordinate < ActiveRecord::Migration[4.2]
  class TempMyModule < ApplicationRecord
    self.table_name = 'my_modules'
  end

  def change
    TempMyModule.find_each do |my_module|
      x = my_module.x
      y = my_module.y
      x *= 32
      y *= 16
      my_module.update(x: x, y: y)
    end
  end
end
