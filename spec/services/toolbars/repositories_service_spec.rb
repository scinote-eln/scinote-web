# frozen_string_literal: true

require 'rails_helper'

describe Toolbars::RepositoriesService do
  let!(:viewer_role) { create :viewer_role }
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }

  before { user.update!(current_team_id: team.id) }

  def names(repositories)
    described_class.new(Repository.where(id: repositories.map(&:id)), user).actions.map { |a| a[:name] }
  end

  it 'returns no actions for an empty selection' do
    expect(described_class.new(Repository.none, user).actions).to eq []
  end

  it 'returns the full action set for a single active repository' do
    expect(names([repository])).to eq ['access', :update, :duplicate, :export, :archive, :share]
  end

  it 'omits single-only actions for multiple repositories' do
    other = create :repository, team: team, created_by: user
    expect(names([repository, other])).to eq %i(export archive)
  end

  it 'returns restore/delete actions for archived repositories' do
    archived = create :repository, :archived, team: team, created_by: user
    expect(names([archived])).to eq ['access', :export, :restore, :delete]
  end

  it 'uses the user export file type and team scoped paths' do
    export = described_class.new(Repository.where(id: repository.id), user).actions.find { |a| a[:name] == :export }
    expect(export[:export_file_type]).to eq 'xlsx'
    expect(export[:path]).to eq Rails.application.routes.url_helpers.export_repositories_team_repositories_path(team)
  end

  it 'hides write actions from a viewer' do
    UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
    expect(names([repository])).to eq %w(access) + [:export]
  end
end
