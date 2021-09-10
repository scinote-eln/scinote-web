# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::WrokflowStatusesController', type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
    MyModuleStatusFlow.ensure_default
  end

  describe 'GET workflow statuses, #index' do
    it 'Response with correct workflow statuses' do
      hash_body = nil
      get api_v1_workflow_workflow_statuses_path(workflow_id: MyModuleStatusFlow.first.id), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(MyModuleStatusFlow.first.my_module_statuses, each_serializer: Api::V1::WorkflowStatusSerializer)
            .to_json
        )['data']
      )
    end
  end
end
