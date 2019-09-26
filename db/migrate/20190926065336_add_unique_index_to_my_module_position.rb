# frozen_string_literal: true

class AddUniqueIndexToMyModulePosition < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      alter table my_modules
        add constraint my_module_unique_position_for_non_archive
        EXCLUDE (x WITH =, y WITH =, experiment_id WITH =)
        WHERE (archived != true)
        DEFERRABLE INITIALLY DEFERRED;
    SQL
  end

  def down
    execute <<-SQL
      alter table my_modules
        drop constraint if exists my_module_unique_position_for_non_archive;
    SQL
  end
end
