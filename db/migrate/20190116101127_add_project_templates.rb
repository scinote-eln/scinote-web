# frozen_string_literal: true

class AddProjectTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :template, :boolean
    add_column :experiments, :uuid, :uuid
  end
end
