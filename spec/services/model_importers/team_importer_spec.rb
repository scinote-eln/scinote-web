# frozen_string_literal: true

require 'rails_helper'

describe TeamImporter do
  describe '#import_template_experiment_from_dir' do
    before :all do
      time = Time.new(2015, 8, 1, 14, 35, 0)
      @user = create :user
      @team = create :team
      @project = create :project, name: 'Project', visibility: 1, team: @team,
                       archived: false, created_at: time

      @team_importer =  TeamImporter.new
      @exp = @team_importer
              .import_template_experiment_from_dir(
                'spec/services/model_importers/test_experiment_data',
                1, 1
              )
    end
    it { expect(@exp.name).to eq 'Experiment export' }
    it { expect(@exp.created_at).to eq '2019-01-21T13:27:53.342Z' }
    it { expect(@exp.archived).to eq '2019-01-21T13:27:53.342Z' }
  end
end
