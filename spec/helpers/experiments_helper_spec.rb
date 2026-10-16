# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }

  describe '#experiments_view_mode' do
    it 'returns archived when the view_mode param is archived' do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(view_mode: 'archived'))

      expect(helper.experiments_view_mode(project)).to eq 'archived'
    end

    it 'returns active for any other value' do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(view_mode: 'x'))

      expect(helper.experiments_view_mode(project)).to eq 'active'
    end
  end

  describe '#grouped_by_prj' do
    it 'groups experiments by project name with the project archived flag' do
      other_project = create :project, team: team, created_by: user
      e1 = create :experiment, project: project, user: user
      e2 = create :experiment, project: project, user: user
      e3 = create :experiment, project: other_project, user: user

      groups = helper.grouped_by_prj(Experiment.where(id: [e1, e2, e3].map(&:id)))

      by_name = groups.index_by { |g| g[:project_name] }
      expect(by_name.keys).to match_array [project.name, other_project.name]
      expect(by_name[project.name][:experiments].map(&:id)).to match_array [e1.id, e2.id]
      expect(by_name[project.name][:project_archived]).to be false
      expect(by_name[other_project.name][:experiments].map(&:id)).to eq [e3.id]
    end
  end

  describe '#experiment_archived_on' do
    it 'returns the experiment archive time when the experiment is archived' do
      experiment = create :experiment, :archived, project: project, user: user

      expect(helper.experiment_archived_on(experiment)).to eq experiment.archived_on
    end

    it 'returns the project archive time when only the project is archived' do
      archived_project = create :project, :archived, team: team, created_by: user
      experiment = create :experiment, project: archived_project, user: user

      expect(helper.experiment_archived_on(experiment)).to eq archived_project.archived_on
    end

    it 'returns nil when nothing is archived' do
      experiment = create :experiment, project: project, user: user

      expect(helper.experiment_archived_on(experiment)).to be_nil
    end
  end
end
