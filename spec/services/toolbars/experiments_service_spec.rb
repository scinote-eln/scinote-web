# frozen_string_literal: true

require 'rails_helper'

describe Toolbars::ExperimentsService do
  let!(:viewer_role) { create :viewer_role }
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let!(:experiment) { create :experiment, project: project, created_by: user }
  let(:routes) { Rails.application.routes.url_helpers }

  before do
    user.update!(current_team_id: team.id)
    allow(AnalyticalReport).to receive(:experiment_reporting_enabled?).and_return(false)
  end

  def actions_for(*experiments)
    described_class.new(user, experiment_ids: experiments.map(&:id)).actions
  end

  def names(*experiments)
    actions_for(*experiments).map { |a| a[:name] }
  end

  it 'returns no actions for an empty or unreadable selection' do
    expect(described_class.new(user, experiment_ids: []).actions).to eq []
    other = create :experiment
    expect(actions_for(other)).to eq []
  end

  it 'returns the full single-experiment action set for an owner' do
    expect(names(experiment)).to eq %w(edit access move duplicate archive)
  end

  it 'adds generateReport when experiment reporting is enabled' do
    allow(AnalyticalReport).to receive(:experiment_reporting_enabled?).and_return(true)
    expect(names(experiment)).to eq %w(edit access move duplicate archive generateReport)
  end

  it 'builds paths scoped to the project and selection' do
    archive = actions_for(experiment).find { |a| a[:name] == 'archive' }
    move = actions_for(experiment).find { |a| a[:name] == 'move' }
    expect(archive[:path]).to eq routes.archive_group_project_experiments_path(project_id: project.id)
    expect(move[:path]).to eq routes.move_experiments_path(ids: [experiment.id])
    expect(archive[:type]).to eq :emit
  end

  it 'omits single-only actions for several experiments' do
    other = create :experiment, project: project, created_by: user
    expect(names(experiment, other)).to eq %w(move archive)
  end

  it 'offers restore for archived experiments' do
    experiment.update!(archived: true, archived_on: Time.zone.now, archived_by: user)
    restore = actions_for(experiment).find { |a| a[:name] == 'restore' }
    expect(restore[:path]).to eq routes.restore_group_project_experiments_path(project_id: project.id)
    expect(names(experiment)).not_to include('archive')
  end

  it 'only shows read-level actions to a viewer' do
    UserAssignment.where(user: user, assignable: [team, project, experiment]).update_all(user_role_id: viewer_role.id)
    expect(names(experiment)).to eq %w(access duplicate) # viewers may clone (read-only duplicate)
  end
end
