# frozen_string_literal: true

require 'rails_helper'

describe AtWhoController, type: :controller do
  login_user
  render_views

  include_context 'reference_project_structure', { team_role: :owner }

  let(:json) { JSON.parse(response.body) }
  let(:query) { '' }

  before { user.update!(current_team_id: team.id) }

  describe 'common filters' do
    it 'returns 404 for an unknown team' do
      get :projects, params: { id: -1, query: query }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 when the user cannot read the team' do
      other_team = create :team, created_by: create(:user)
      get :projects, params: { id: other_team.id, query: query }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET users' do
    let!(:colleague) do
      create :user, full_name: 'Zeppelin Colleague', email: 'zeppelin@example.com', confirmed_at: Time.zone.now
    end
    let!(:outsider) { create :user, full_name: 'Zeppelin Outsider', confirmed_at: Time.zone.now }

    before { create :user_assignment, user: colleague, assignable: team, user_role: owner_role }

    it 'renders team users matching the query' do
      get :users, params: { id: team.id, query: 'zeppelin' }, format: :json
      html = json['users'].first
      expect(response).to have_http_status(:ok)
      expect(html).to include('Zeppelin Colleague', colleague.id.base62_encode)
      expect(html).not_to include('Zeppelin Outsider')
    end

    it 'renders the no results block when nobody matches' do
      get :users, params: { id: team.id, query: 'no-such-person-xyz' }, format: :json
      expect(json['users'].first).to include('atwho-no-results', I18n.t('atwho.no_results.users'))
    end
  end

  describe 'GET menu_items' do
    let!(:other_project) { create :project, team: team, created_by: user, name: 'Zebra project' }

    it 'returns projects, experiments and tasks' do
      get :menu_items, params: { id: team.id, query: '' }, format: :json
      expect(json['status']).to eq 'ok'
      expect(json['prj'].map { |p| p['id'] }).to include(project.id)
      expect(json['exp'].map { |e| e['id'] }).to include(experiment.id)
      expect(json['tsk'].map { |t| t['id'] }).to include(my_module.id)
    end

    it 'filters by query' do
      get :menu_items, params: { id: team.id, query: 'Zebra' }, format: :json
      expect(json['prj'].map { |p| p['id'] }).to eq [other_project.id]
    end
  end

  describe 'GET projects' do
    it 'renders matching projects' do
      get :projects, params: { id: team.id, query: project.name }, format: :json
      expect(response).to have_http_status(:ok)
      expect(json['team']).to eq team.id
      expect(json['res'].first).to include(project.name)
    end
  end

  describe 'GET experiments' do
    it 'renders matching experiments' do
      get :experiments, params: { id: team.id, query: experiment.name }, format: :json
      expect(json['team']).to eq team.id
      expect(json['res'].first).to include(experiment.name)
    end
  end

  describe 'GET my_modules' do
    it 'renders matching tasks' do
      get :my_modules, params: { id: team.id, query: my_module.name }, format: :json
      expect(json['team']).to eq team.id
      expect(json['res'].first).to include(my_module.name)
    end
  end

  describe 'GET menu' do
    let!(:repository) { create :repository, team: team, created_by: user, name: 'Menu inventory' }

    before { create :repository, team: team, created_by: user, name: 'Second inventory' }

    it 'lists readable repositories in the menu' do
      get :menu, params: { id: team.id }, format: :json
      expect(json['html']).to include('Menu inventory', 'Second inventory', "data-object-id=\"#{repository.id}\"")
    end
  end

  describe 'GET rep_items' do
    let!(:repository) { create :repository, team: team, created_by: user, name: 'Samples' }
    let!(:row) { create :repository_row, repository: repository, created_by: user, name: 'Alpha sample' }
    let!(:other_row) { create :repository_row, repository: repository, created_by: user, name: 'Beta sample' }

    it 'returns rows of the given repository filtered by query' do
      get :rep_items, params: { id: team.id, repository_id: repository.id, query: 'Alpha' }, format: :json
      expect(json['repository']).to eq repository.id
      expect(json['team']).to eq team.id
      expect(json['res'].first).to include('Alpha sample')
      expect(json['res'].first).not_to include('Beta sample')
    end

    it 'falls back to the first readable repository without repository_id' do
      get :rep_items, params: { id: team.id, query: 'Alpha' }, format: :json
      expect(json['repository']).to eq Repository.active.readable_by_user(user, team).first.id
    end

    it 'returns no repository when the repository does not exist' do
      get :rep_items, params: { id: team.id, repository_id: -1, query: '' }, format: :json
      expect(json['repository']).to be_nil
    end

    it 'returns no items when the repository cannot be read' do
      foreign = create :repository, created_by: create(:user)
      get :rep_items, params: { id: team.id, repository_id: foreign.id, query: '' }, format: :json
      expect(json['repository']).to be_nil
    end

    it 'passes the readable assignable task to the search' do
      get :rep_items,
          params: { id: team.id, repository_id: repository.id, assignable_my_module_id: my_module.id,
                    query: 'Alpha' },
          format: :json
      expect(json['repository']).to eq repository.id
      expect(json['res'].first).to include('Alpha sample')
    end
  end
end
