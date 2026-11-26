# frozen_string_literal: true

require 'rails_helper'

describe UserRolesHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:viewer_role) { UserRole.find_predefined_viewer_role || create(:viewer_role) }

  before do
    viewer_role
    without_partial_double_verification { allow(helper).to receive(:current_team).and_return(team) }
  end

  describe '#user_roles_collection' do
    it 'lists the roles that carry project permissions ordered by id as name/id pairs' do
      roles = helper.user_roles_collection(project)

      expected = UserRole.where('permissions && ARRAY[?]::varchar[]', ProjectPermissions.constants.map { |c| ProjectPermissions.const_get(c) })
                         .order(:id).pluck(:name, :id)
      expect(roles).to eq expected
      expect(roles).to include([UserRole.find_predefined_owner_role.name, UserRole.find_predefined_owner_role.id])
    end

    it 'prepends the inherit option with its description when with_inherit is set' do
      roles = helper.user_roles_collection(project, with_inherit: true)

      expect(roles.first[0]).to eq 'Inherit role'
      expect(roles.first[1]).to eq 'reset'
      expect(roles.drop(1)).to eq helper.user_roles_collection(project)
    end

    context 'when the object is only shared read with the current team' do
      let(:other_team) { create :team, created_by: create(:user) }
      let(:repository) { create :repository, team: other_team, created_by: other_team.created_by }

      it 'only offers the viewer role' do
        create :team_shared_object, :read, team: team, shared_object: repository

        expect(helper.user_roles_collection(repository)).to eq [[viewer_role.name, viewer_role.id]]
      end
    end
  end

  describe 'team role helpers' do
    let!(:normal_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.normal_user')) || create(:normal_user_role) }

    it '#team_user_roles_collection returns roles with team permissions, most permissive first' do
      roles = helper.team_user_roles_collection
      owner = UserRole.find_predefined_owner_role

      expect(roles).to include(owner, normal_role)
      expect(roles.first).to eq owner
      team_permissions = PermissionExtends::TeamPermissions.constants.map { |c| TeamPermissions.const_get(c) } +
                         ProtocolPermissions.constants.map { |c| ProtocolPermissions.const_get(c) } +
                         RepositoryPermissions.constants.map { |c| RepositoryPermissions.const_get(c) }
      counts = roles.map { |r| (r.permissions & team_permissions).length }
      expect(counts).to eq counts.sort.reverse
    end

    it '#team_user_roles_for_select returns name and id pairs' do
      pairs = helper.team_user_roles_for_select

      expect(pairs).to include([UserRole.find_predefined_owner_role.name, UserRole.find_predefined_owner_role.id])
      expect(pairs.map(&:last)).to match_array(helper.team_user_roles_collection.map(&:id))
    end

    it '#managing_team_user_roles_collection returns only roles that can manage team users' do
      roles = helper.managing_team_user_roles_collection

      expect(roles).to include(UserRole.find_predefined_owner_role)
      expect(roles).not_to include(viewer_role)
      expect(roles).to all(satisfy { |r| r.permissions.include?(TeamPermissions::USERS_MANAGE) })
    end
  end
end
