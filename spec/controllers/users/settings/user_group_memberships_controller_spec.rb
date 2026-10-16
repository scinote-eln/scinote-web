# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::UserGroupMembershipsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }
  let!(:group) { create :user_group, team: team, created_by: user, last_modified_by: user }
  let(:member) { create :user }
  let(:member2) { create :user }
  let(:outsider) { create :user }
  let(:groups_enabled) { true }
  let(:base) { { team_id: team.id, user_group_id: group.id } }

  before do
    allow(UserGroup).to receive(:enabled?).and_return(groups_enabled)
    normal = UserRole.find_by(name: I18n.t('user_roles.predefined.normal_user')) || create(:normal_user_role)
    create_user_assignment(team, normal, member)
    create_user_assignment(team, normal, member2)
  end

  def make_team_viewer!
    team.user_assignments.find_by(user: user).update!(user_role: viewer_role)
  end

  describe 'when user groups are disabled' do
    let(:groups_enabled) { false }

    it 'renders the promo page' do
      get :index, params: base, format: :json
      expect(response).to render_template('users/settings/user_groups/promo')
    end
  end

  describe 'GET index' do
    let!(:m1) { create :user_group_membership, user_group: group, user: member, created_by: user }
    let!(:m2) { create :user_group_membership, user_group: group, user: member2, created_by: user }

    it 'lists the memberships with user data' do
      get :index, params: base, format: :json
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)['data'].map { |d| d['attributes'] }
      expect(data.pluck('email')).to match_array([member.email, member2.email])
      expect(data.pluck('name')).to match_array([member.full_name, member2.full_name])
    end

    it 'filters by search' do
      get :index, params: base.merge(search: member.email), format: :json
      emails = JSON.parse(response.body)['data'].map { |d| d['attributes']['email'] }
      expect(emails).to eq [member.email]
    end

    it 'sorts by email descending' do
      get :index, params: base.merge(order: { column: 'email', dir: 'desc' }), format: :json
      emails = JSON.parse(response.body)['data'].map { |d| d['attributes']['email'] }
      expect(emails).to eq [member.email, member2.email].sort.reverse
    end

    # The controller uses Team#user_groups.find and lets RecordNotFound escape; Rails maps it to 404
    # outside of controller specs (the app has no rescue_from for it).
    it 'raises not found for a group of another team, which Rails maps to a 404' do
      expect(ActionDispatch::ExceptionWrapper.status_code_for_exception('ActiveRecord::RecordNotFound')).to eq 404
      foreign = create :user_group
      expect { get :index, params: { team_id: team.id, user_group_id: foreign.id }, format: :json }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST actions_toolbar' do
    let!(:m1) { create :user_group_membership, user_group: group, user: member, created_by: user }

    it 'returns the remove action' do
      post :actions_toolbar, params: base.merge(items: [{ id: m1.id }].to_json), format: :json
      actions = JSON.parse(response.body)['actions']
      expect(actions.pluck('name')).to eq ['delete']
    end

    it 'returns no actions when nothing matches' do
      post :actions_toolbar, params: base.merge(items: [{ id: 0 }].to_json), format: :json
      expect(JSON.parse(response.body)['actions']).to eq []
    end
  end

  describe 'POST create' do
    it 'adds team users and logs activities' do
      expect do
        post :create, params: base.merge(user_ids: [member.id, member2.id]), format: :json
      end.to change { group.user_group_memberships.count }.by(2)
         .and change { Activity.where(type_of: :add_group_user_member).count }.by(2)
      expect(response).to have_http_status(:created)
      expect(group.users).to match_array([member, member2])
      expect(group.user_group_memberships.pluck(:created_by_id).uniq).to eq [user.id]
    end

    it 'ignores users that are not in the team' do
      expect { post :create, params: base.merge(user_ids: [outsider.id]), format: :json }
        .not_to(change { group.user_group_memberships.count })
      expect(response).to have_http_status(:created)
    end

    it 'rolls back and returns 422 when a member is already in the group' do
      create :user_group_membership, user_group: group, user: member, created_by: user
      allow(Rails.logger).to receive(:error)
      expect do
        post :create, params: base.merge(user_ids: [member2.id, member.id]), format: :json
      end.not_to(change { group.user_group_memberships.count })
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      expect { post :create, params: base.merge(user_ids: [member.id]), format: :json }
        .not_to(change { group.user_group_memberships.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE destroy_multiple' do
    let!(:m1) { create :user_group_membership, user_group: group, user: member, created_by: user }
    let!(:m2) { create :user_group_membership, user_group: group, user: member2, created_by: user }

    it 'removes the given memberships and logs activities' do
      expect do
        delete :destroy_multiple, params: base.merge(membership_ids: [m1.id]), format: :json
      end.to change { group.user_group_memberships.count }.by(-1)
         .and change { Activity.where(type_of: :remove_group_user_member).count }.by(1)
      expect(response).to have_http_status(:ok)
      expect(group.users).to eq [member2]
    end

    it 'does not remove memberships of other groups' do
      other = create :user_group, team: team
      foreign = create :user_group_membership, user_group: other, user: member, created_by: user
      expect { delete :destroy_multiple, params: base.merge(membership_ids: [foreign.id]), format: :json }
        .not_to change(UserGroupMembership, :count)
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      expect { delete :destroy_multiple, params: base.merge(membership_ids: [m1.id]), format: :json }
        .not_to change(UserGroupMembership, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
