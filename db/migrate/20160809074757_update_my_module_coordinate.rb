class UpdateMyModuleCoordinate < ActiveRecord::Migration
	def change
		MyModule.all.each do |my_module|
			x = my_module.x
			y = my_module.y
			x *= 32
			y *= 16
			my_module.update(x: x)
			my_module.update(y: y)
		end
	end
end
