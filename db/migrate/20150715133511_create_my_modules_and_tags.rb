class CreateMyModulesAndTags < ActiveRecord::Migration
  def change
    create_table :my_module_tags do |t|
      t.belongs_to :my_module, index: true
      t.belongs_to :tag, index: true
    end
  end
end
