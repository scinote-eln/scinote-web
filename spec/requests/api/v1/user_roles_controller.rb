# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::UserRolesController', type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 3, created_by: @user)
    create :owner_role
    create :technician_role
    create :viewer_role
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET teams, #index' do
    it 'Response with correct roles' do
      hash_body = nil
      get api_v1_user_roles_path, headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
                                    ActiveModelSerializers::SerializableResource
                                      .new(UserRole.all, each_serializer: Api::V1::UserRoleSerializer)
                                      .as_json[:data]
                                  )
    end
  end
end
