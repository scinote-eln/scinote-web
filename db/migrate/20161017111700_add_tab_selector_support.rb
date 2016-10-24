class AddTabSelectorSupport < ActiveRecord::Migration
  def up
    add_column :my_modules,
               :shown_tabs,
               :jsonb,
               null: false,
               default: []

    MyModule.update_all(shown_tabs: %w(protocols results samples))
  end

  def down
    remove_column :my_modules, :shown_tabs
  end
end
