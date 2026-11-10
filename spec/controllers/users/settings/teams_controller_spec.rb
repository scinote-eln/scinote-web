# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::TeamsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:viewer_role) { create :viewer_role }

  let(:datatable_params) do
    { draw: 1, start: 0, length: 10,
      order: { '0' => { column: 0, dir: 'asc' } },
      search: { value: '', regex: 'false' },
      columns: (0..4).index_with do |i|
        { data: i.to_s, orderable: 'true', searchable: 'true', search: { value: '', regex: 'false' } }
      end }
  end

  def make_team_viewer!
    team.user_assignments.find_by(user: user).update!(user_role: viewer_role)
  end

  describe 'GET index' do
    it 'counts the teams the user is a member of' do
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:member_of)).to eq user.teams.count
    end
  end

  describe 'POST datatable' do
    it 'renders the teams datatable as json' do
      post :datatable, params: datatable_params, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('data')
    end
  end

  describe 'GET new' do
    it 'builds a new team' do
      get :new
      expect(response).to have_http_status(:success)
      expect(assigns(:new_team)).to be_new_record
    end
  end

  describe 'POST create' do
    before { allow_any_instance_of(Team).to receive(:generate_template_project) }

    it 'creates a team owned by the user and redirects to it' do
      expect { post :create, params: { team: { name: 'Brand new team', description: 'd' } } }
        .to change(Team, :count).by(1)
      created = Team.find_by(name: 'Brand new team')
      expect(created.created_by).to eq user
      expect(response).to redirect_to(team_path(created))
    end

    it 're-renders new when the team is invalid' do
      expect { post :create, params: { team: { name: '' } } }.not_to change(Team, :count)
      expect(response).to render_template(:new)
    end

    it 'is forbidden when the user cannot create teams' do
      allow(controller).to receive(:can_create_teams?).and_return(false)
      expect { post :create, params: { team: { name: 'Nope' } } }.not_to change(Team, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET show / members / data_integrity' do
    it 'shows the team details tab' do
      get :show, params: { id: team.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:active_tab)).to eq :details
    end

    it 'shows the members tab' do
      get :members, params: { id: team.id }
      expect(assigns(:active_tab)).to eq :members
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      get :show, params: { id: team.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'renders data integrity when deletion prevention is enabled' do
      allow(Team).to receive(:deletion_prevention_enabled?).and_return(true)
      get :data_integrity, params: { id: team.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:active_tab)).to eq :data_integrity
    end

    it 'forbids data integrity when deletion prevention is disabled' do
      allow(Team).to receive(:deletion_prevention_enabled?).and_return(false)
      get :data_integrity, params: { id: team.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST users_datatable' do
    it 'renders the team users datatable' do
      post :users_datatable, params: datatable_params.merge(id: team.id), format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['data'].length).to eq 1
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      post :users_datatable, params: { id: team.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET name_html / description_html' do
    # bug: partial users/settings/teams/_name_modal_body does not exist, the action always fails
    it 'raises MissingTemplate for the name modal' do
      expect { get :name_html, params: { id: team.id }, format: :json }
        .to raise_error(ActionView::MissingTemplate)
    end

    it 'returns the description modal html' do
      get :description_html, params: { id: team.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('html')
    end
  end

  describe 'PUT update' do
    it 'updates the team and returns the rendered description' do
      put :update, params: { id: team.id, team: { name: 'Renamed team', description: 'New description' } },
                   format: :json
      expect(response).to have_http_status(:success)
      body = JSON.parse(response.body)
      expect(body['status']).to eq 'ok'
      expect(body['html']).to include('New description')
      team.reload
      expect(team.name).to eq 'Renamed team'
      expect(team.last_modified_by).to eq user
    end

    it 'returns validation errors' do
      put :update, params: { id: team.id, team: { name: '' } }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key('name')
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      put :update, params: { id: team.id, team: { name: 'Hacked' } }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(team.reload.name).not_to eq 'Hacked'
    end
  end

  describe 'DELETE destroy' do
    # bug: the team is destroyed but `redirect_to action: :index` raises ArgumentError because
    # ActionView::Helpers::UrlHelper (included in the controller) overrides url_for
    it 'destroys the team but fails to redirect to the list' do
      user.update!(current_team_id: create(:team, created_by: user).id)
      expect do
        expect { delete :destroy, params: { id: team.id } }.to raise_error(ArgumentError)
      end.to change(Team, :count).by(-1)
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      expect { delete :destroy, params: { id: team.id } }.not_to change(Team, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST switch' do
    it 'switches the current team' do
      other = create :team, created_by: user
      post :switch, params: { team_id: other.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)['current_team']).to eq other.id
      expect(user.reload.current_team_id).to eq other.id
    end

    it 'rejects a team the user is not a member of' do
      foreign = create :team
      post :switch, params: { team_id: foreign.id }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.current_team_id).not_to eq foreign.id
    end
  end
end
