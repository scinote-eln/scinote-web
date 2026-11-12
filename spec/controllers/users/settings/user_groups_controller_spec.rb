# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::UserGroupsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:viewer_role) { create :viewer_role }
  let!(:group) { create :user_group, team: team, created_by: user, last_modified_by: user, name: 'Group A' }
  let(:member) { create :user }
  let(:groups_enabled) { true }

  def make_team_viewer!
    team.user_assignments.find_by(user: user).update!(user_role: viewer_role)
  end

  before do
    allow(UserGroup).to receive(:enabled?).and_return(groups_enabled)
    create_user_assignment(team, UserRole.find_by(name: I18n.t('user_roles.predefined.normal_user')) ||
                                 create(:normal_user_role), member)
  end

  describe 'when user groups are disabled' do
    let(:groups_enabled) { false }

    it 'renders the promo page' do
      get :index, params: { team_id: team.id }
      expect(response).to render_template('users/settings/user_groups/promo')
    end

    it 'still allows reading group users' do
      get :users, params: { team_id: team.id, id: group.id }, format: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET index' do
    it 'renders html' do
      get :index, params: { team_id: team.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:active_tab)).to eq :user_groups
    end

    it 'lists groups as json' do
      get :index, params: { team_id: team.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(response.body).to include('Group A')
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      get :index, params: { team_id: team.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET show' do
    it 'renders the group page' do
      get :show, params: { team_id: team.id, id: group.id }
      expect(response).to have_http_status(:success)
    end

    it 'raises not found for a group of another team' do
      foreign = create :user_group
      expect { get :show, params: { team_id: team.id, id: foreign.id } }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST actions_toolbar' do
    it 'returns toolbar actions' do
      post :actions_toolbar, params: { team_id: team.id, items: [{ id: group.id }].to_json }, format: :json
      expect(response).to have_http_status(:success)
      expect(JSON.parse(response.body)).to have_key('actions')
    end
  end

  describe 'GET unassigned_users' do
    it 'returns team users not in the group' do
      group.user_group_memberships.create!(user: member, created_by: user)
      get :unassigned_users, params: { team_id: team.id, user_group_id: group.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(assigns(:unassigned_users)).to include(user)
      expect(assigns(:unassigned_users)).not_to include(member)
    end

    it 'returns all team users without a group' do
      get :unassigned_users, params: { team_id: team.id }, format: :json
      expect(assigns(:unassigned_users)).to include(user, member)
    end
  end

  describe 'POST create' do
    it 'creates a group with members and logs activities' do
      expect do
        post :create, params: { team_id: team.id,
                                user_group: { name: 'New group',
                                              user_group_memberships_attributes: [{ user_id: member.id }] } },
                      format: :json
      end.to change(UserGroup, :count).by(1)
         .and change { Activity.where(type_of: :create_user_group).count }.by(1)
         .and change { Activity.where(type_of: :add_group_user_member).count }.by(1)
      expect(response).to have_http_status(:created)
      created = UserGroup.find_by(name: 'New group')
      expect(created.created_by).to eq user
      expect(created.users).to include(member)
    end

    it 'returns errors for an invalid group' do
      expect { post :create, params: { team_id: team.id, user_group: { name: '' } }, format: :json }
        .not_to change(UserGroup, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to be_present
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      expect { post :create, params: { team_id: team.id, user_group: { name: 'Nope' } }, format: :json }
        .not_to change(UserGroup, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update' do
    it 'updates the group and logs an activity' do
      expect do
        put :update, params: { team_id: team.id, id: group.id, user_group: { name: 'Renamed' } }, format: :json
      end.to change { Activity.where(type_of: :update_user_group).count }.by(1)
      expect(response).to have_http_status(:ok)
      expect(group.reload.name).to eq 'Renamed'
    end

    it 'returns errors for invalid data and keeps the group' do
      expect do
        put :update, params: { team_id: team.id, id: group.id, user_group: { name: '' } }, format: :json
      end.not_to(change { Activity.where(type_of: :update_user_group).count })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(group.reload.name).to eq 'Group A'
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      put :update, params: { team_id: team.id, id: group.id, user_group: { name: 'Renamed' } }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(group.reload.name).to eq 'Group A'
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the group and logs an activity' do
      expect do
        delete :destroy, params: { team_id: team.id, id: group.id }, format: :json
      end.to change(UserGroup, :count).by(-1)
         .and change { Activity.where(type_of: :delete_user_group).count }.by(1)
      expect(response).to have_http_status(:ok)
    end

    it 'returns an error when destroy fails' do
      allow_any_instance_of(UserGroup).to receive(:destroy).and_return(false)
      delete :destroy, params: { team_id: team.id, id: group.id }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      expect { delete :destroy, params: { team_id: team.id, id: group.id }, format: :json }
        .not_to change(UserGroup, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET users' do
    it 'returns the users of the group' do
      group.user_group_memberships.create!(user: member, created_by: user)
      get :users, params: { team_id: team.id, id: group.id }, format: :json
      expect(response).to have_http_status(:success)
      expect(response.body).to include(member.full_name)
    end

    it 'is allowed for a team viewer (read permission)' do
      make_team_viewer!
      get :users, params: { team_id: team.id, id: group.id }, format: :json
      expect(response).to have_http_status(:success)
    end
  end
end
