# frozen_string_literal: true

require 'rails_helper'

describe Toolbars::ProjectsService do
  let!(:viewer_role) { create :viewer_role }
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:project) { create :project, team: team, created_by: user }
  let!(:folder) { create :project_folder, team: team }
  let(:routes) { Rails.application.routes.url_helpers }

  before { user.update!(current_team_id: team.id) }

  def actions_for(projects, folders = [])
    described_class.new(projects, folders, user).actions
  end

  def names(projects, folders = [])
    actions_for(projects, folders).map { |a| a[:name] }
  end

  it 'returns no actions for an empty selection' do
    expect(actions_for([], [])).to eq []
  end

  it 'returns the full action set for a single active project' do
    expect(names([project])).to eq %w(edit access move export archive comments activities)
  end

  it 'builds project specific paths' do
    result = actions_for([project]).index_by { |a| a[:name] }
    expect(result['archive'][:path]).to eq routes.archive_group_projects_path
    expect(result['move'][:path]).to eq routes.move_to_modal_project_folders_path
    expect(result['export'][:path]).to eq routes.export_projects_team_path(team)
    expect(result['export'][:number_of_projects]).to eq 1
    expect(result['activities'][:type]).to eq :link
    expect(result['activities'][:path]).to start_with('/global_activities?')
  end

  it 'restricts a folder selection to edit, move, export and delete' do
    expect(names([], [folder])).to eq %w(edit move export delete_folders)
  end

  it 'counts readable projects inside folders for export' do
    project.update!(project_folder: folder)
    export = actions_for([], [folder]).find { |a| a[:name] == 'export' }
    expect(export[:number_of_projects]).to eq 1
  end

  it 'drops single-only actions for a mixed selection' do
    expect(names([project], [folder])).to eq %w(move export)
  end

  it 'drops single-only actions for several projects' do
    other = create :project, team: team, created_by: user
    expect(names([project, other])).to eq %w(move export archive)
  end

  it 'offers restore instead of archive for archived projects' do
    project.update!(archived: true, archived_on: Time.zone.now, archived_by: user)
    result = names([project])
    expect(result).to include('restore')
    expect(result).not_to include('archive')
  end

  it 'shows the export limit message when no requests are left' do
    allow(TeamZipExport).to receive(:exports_limit).and_return(5)
    allow(user).to receive(:exports_left).and_return(1)
    export = actions_for([project]).find { |a| a[:name] == 'export' }
    expect(export[:number_of_request_left]).to eq 0
    expect(export[:message]).not_to include('<i>')
  end

  it 'shows the remaining export requests when under the limit' do
    allow(TeamZipExport).to receive(:exports_limit).and_return(5)
    allow(user).to receive(:exports_left).and_return(4)
    export = actions_for([project]).find { |a| a[:name] == 'export' }
    expect(export[:number_of_request_left]).to eq 3
    expect(export[:message]).to include('<i>')
  end

  it 'limits a viewer' do
    UserAssignment.where(user: user, assignable: [team, project]).update_all(user_role_id: viewer_role.id)
    result = names([project])
    expect(result).to include('access', 'comments', 'activities')
    expect(result).not_to include('edit', 'archive', 'move')
  end
end
