class AddTabSelectorSupport < ActiveRecord::Migration
  def up
    add_column :my_modules,
               :shown_tabs,
               :jsonb,
               default: [],
               null: false

    MyModule.update_all(shown_tabs: %w(overview) + Constants::WIDGET_TYPES)
  end

  def down
    remove_column :my_modules, :shown_tabs
  end
end
