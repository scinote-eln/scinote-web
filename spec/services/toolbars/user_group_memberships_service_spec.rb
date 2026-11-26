# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Toolbars::UserGroupMembershipsService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:group) { create :user_group, team: team, created_by: user }
  let(:member) { create :user }
  let(:viewer) { create :user }
  before { [user, viewer].each { |u| u.update!(current_team_id: team.id) } }

  let!(:membership) { create :user_group_membership, user_group: group, user: member, created_by: user }

  def actions_for(ids, service_user: user)
    described_class.new(service_user, group, user_group_membership_ids: ids).actions
  end

  it 'returns no actions without matching memberships' do
    expect(actions_for([])).to eq []
    expect(actions_for([0])).to eq []
  end

  it 'returns a remove action with the destroy path for a team admin' do
    actions = actions_for([membership.id])
    expect(actions.size).to eq 1
    expect(actions.first).to include(name: 'delete', label: 'Remove', type: :emit)
    expect(actions.first[:path]).to eq(
      Rails.application.routes.url_helpers
           .destroy_multiple_users_settings_team_user_group_user_group_memberships_path(
             team, group, membership_ids: [membership.id]
           )
    )
  end

  it 'ignores memberships of other groups' do
    other = create :user_group_membership, user: member, created_by: user
    expect(actions_for([other.id])).to eq []
  end

  it 'returns no actions for a user who cannot manage the team' do
    role = UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role)
    create_user_assignment(team, role, viewer)
    expect(actions_for([membership.id], service_user: viewer)).to eq []
  end
end
