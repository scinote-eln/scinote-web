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
      get :search, params: { id: -1, query: query }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 when the user cannot read the team' do
      other_team = create :team, created_by: create(:user)
      get :search, params: { id: other_team.id, query: query }, format: :json
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
      expect(response).to have_http_status(:ok)
      expect(json['users'].map { |u| u['full_name'] }).to eq ['Zeppelin Colleague']
      expect(json['users'].first).to include('id' => colleague.id.base62_encode, 'email' => 'zeppelin@example.com')
      expect(json['limit_reached']).to be false
    end

    it 'renders no users when nobody matches' do
      get :users, params: { id: team.id, query: 'no-such-person-xyz' }, format: :json
      expect(json['users']).to be_empty
    end
  end

  describe 'GET search' do
    let!(:other_project) { create :project, team: team, created_by: user, name: 'Zebra project' }

    def ids_of(type)
      json['items'].select { |i| i['type'] == type }.map { |i| i['id'] }
    end

    it 'searches across all types without a parent_type' do
      get :search, params: { id: team.id, query: '' }, format: :json
      expect(response).to have_http_status(:ok)
      expect(ids_of('prj')).to include(project.id)
      expect(ids_of('exp')).to include(experiment.id)
      expect(ids_of('tsk')).to include(my_module.id)
      expect(json['limit_reached']).to be false
    end

    it 'filters by query' do
      get :search, params: { id: team.id, query: 'Zebra', parent_type: 'sa-projects' }, format: :json
      expect(ids_of('prj')).to eq [other_project.id]
    end

    it 'lists experiments of a project for a parent_id' do
      get :search, params: { id: team.id, query: '', parent_type: 'sa-projects', parent_id: project.id },
                   format: :json
      expect(ids_of('exp')).to eq [experiment.id]
    end

    it 'lists tasks of an experiment for a parent_id' do
      get :search, params: { id: team.id, query: '', parent_type: 'sa-experiments', parent_id: experiment.id },
                   format: :json
      expect(ids_of('tsk')).to eq [my_module.id]
    end

    it 'lists readable repositories at the root' do
      repository = create :repository, team: team, created_by: user, name: 'Menu inventory'
      get :search, params: { id: team.id, query: 'Menu', parent_type: 'sa-repositories' }, format: :json
      expect(ids_of('rep')).to eq [repository.id]
    end

    describe 'sa-repositories with a parent_id' do
      let!(:repository) { create :repository, team: team, created_by: user, name: 'Samples' }
      let!(:row) { create :repository_row, repository: repository, created_by: user, name: 'Alpha sample' }

      before { create :repository_row, repository: repository, created_by: user, name: 'Beta sample' }

      it 'returns rows of the repository filtered by query' do
        get :search, params: { id: team.id, query: 'Alpha', parent_type: 'sa-repositories',
                               parent_id: repository.id },
                     format: :json
        expect(json['items'].map { |i| i['name'] }).to eq ['Alpha sample']
        expect(json['items'].first).not_to have_key('row_assigned')
      end

      it 'returns no items when the repository cannot be read' do
        foreign = create :repository, created_by: create(:user)
        get :search, params: { id: team.id, query: '', parent_type: 'sa-repositories', parent_id: foreign.id },
                     format: :json
        expect(json['items']).to be_empty
      end

      it 'marks assignment for a readable assignable task' do
        get :search, params: { id: team.id, query: 'Alpha', parent_type: 'sa-repositories',
                               parent_id: repository.id, assignable_my_module_id: my_module.id },
                     format: :json
        expect(json['items'].first).to include('row_assigned' => false, 'my_module_id' => my_module.id,
                                               'repository_row_id' => row.id)
      end

      it 'ignores an assignable task the user cannot read' do
        foreign_task = create :my_module, created_by: create(:user)
        get :search, params: { id: team.id, query: 'Alpha', parent_type: 'sa-repositories',
                               parent_id: repository.id, assignable_my_module_id: foreign_task.id },
                     format: :json
        expect(json['items'].first).not_to have_key('row_assigned')
      end

      it 'marks assignment for a readable assignable protocol' do
        protocol = create :protocol, :in_repository_draft, team: team, added_by: user
        get :search, params: { id: team.id, query: 'Alpha', parent_type: 'sa-repositories',
                               parent_id: repository.id, assignable_protocol_id: protocol.id },
                     format: :json
        expect(json['items'].first).to include('row_assigned' => false, 'protocol_id' => protocol.id,
                                               'repository_row_id' => row.id)
      end

      it 'ignores an assignable protocol the user cannot read' do
        foreign_protocol = create :protocol, :in_repository_draft, added_by: create(:user)
        get :search, params: { id: team.id, query: 'Alpha', parent_type: 'sa-repositories',
                               parent_id: repository.id, assignable_protocol_id: foreign_protocol.id },
                     format: :json
        expect(json['items'].first).not_to have_key('row_assigned')
      end
    end
  end
end
