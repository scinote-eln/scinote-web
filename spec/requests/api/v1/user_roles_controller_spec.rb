# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::UserRolesController', type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 3, created_by: @user)
    # role names are unique and rails_helper already creates the owner role, so reuse predefined roles when they exist
    UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) || create(:owner_role)
    UserRole.find_by(name: I18n.t('user_roles.predefined.technician')) || create(:technician_role)
    UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role)
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET user_roles, #index' do
    it 'Response with correct roles' do
      get api_v1_user_roles_path, headers: @valid_headers

      expect(response).to have_http_status(:ok)
      expected_roles = JSON.parse(
        ActiveModelSerializers::SerializableResource
          .new(UserRole.all, each_serializer: Api::V1::UserRoleSerializer)
          .to_json
      )['data']
      expect(json[:data]).to match_array(expected_roles)
    end
  end
end
