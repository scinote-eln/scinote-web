# frozen_string_literal: true

class AddRepositoryTemplatesToTeams < ActiveRecord::Migration[7.0]
  def up
    Team.find_each do |team|
      RepositoryTemplate.default.update!(team: team)
      RepositoryTemplate.cell_lines.update!(team: team)
      RepositoryTemplate.equipment.update!(team: team)
      RepositoryTemplate.chemicals_and_reagents.update!(team: team)
    end
  end

  def down
    RepositoryTemplate.destroy_all
  end
end
