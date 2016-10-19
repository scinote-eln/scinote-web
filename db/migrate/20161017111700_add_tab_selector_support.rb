class AddTabSelectorSupport < ActiveRecord::Migration
  def up
    add_column :my_modules,
               :shown_tabs,
               :jsonb,
               default: [],
               null: false

    MyModule.update_all(shown_tabs:
      %w(scinote_protocols scinote_results scinote_activities scinote_samples))
  end

  def down
    remove_column :my_modules, :shown_tabs
  end
end
