# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::UserGroupsController', type: :request do
  before :all do
    @user = create(:user)
    @group_user1 = create(:user)
    @group_user2 = create(:user)
    @another_group_user1 = create(:user)
    @another_group_user2 = create(:user)
    @team = create(:team, created_by: @user)
    @normal_user_role = create :normal_user_role
    create_user_assignment(@team, @normal_user_role, @group_user1)
    create_user_assignment(@team, @normal_user_role, @group_user2)
    create_user_assignment(@team, @normal_user_role, @another_group_user1)
    create_user_assignment(@team, @normal_user_role, @another_group_user2)
    @user_group = create(:user_group, team: @team, created_by: @user, last_modified_by: @user)
    @another_user_group = create(:user_group, team: @team, created_by: @user, last_modified_by: @user)
    create(:user_group_membership, user: @group_user1, user_group: @user_group, created_by: @user)
    create(:user_group_membership, user: @group_user2, user_group: @user_group, created_by: @user)
    create(:user_group_membership, user: @another_group_user1, user_group: @another_user_group, created_by: @user)
    create(:user_group_membership, user: @another_group_user2, user_group: @another_user_group, created_by: @user)
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET user_groups, #index' do
    it 'Response with correct user_groups' do
      hash_body = nil
      get api_v2_team_user_groups_path(team_id: @team.id), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(ActiveModelSerializers::SerializableResource
          .new(@team.user_groups.all, each_serializer: Api::V2::UserGroupSerializer)
          .to_json)['data']
      )
    end
  end
end
