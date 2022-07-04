# frozen_string_literal: true

class AddRepositoryToLabelTemplates < ActiveRecord::Migration[6.1]
  def change
    add_reference :label_templates, :repository, null: true, foreign_key: true
  end
end
