# frozen_string_literal: true

class AddSmartAnnotationFlagToRepositoryTextValue < ActiveRecord::Migration[7.0]
  def up
    add_column :repository_text_values, :has_smart_annotation, :boolean, null: false, default: false

    execute('UPDATE repository_text_values SET has_smart_annotation = TRUE ' \
            'WHERE data ~ \'\[(@(.*?)|\#(.*?)~(prj|exp|tsk|rep_item))~([0-9a-zA-Z]+)\]\'')
  end

  def down
    remove_column :repository_text_values, :has_smart_annotation
  end
end
