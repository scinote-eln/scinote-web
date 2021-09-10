# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::WrokflowsController', type: :request do
  before :all do
    @user = create(:user)
    @teams = create_list(:team, 2, created_by: @user)
    create(:user_team, user: @user, team: @teams.first, role: 2)
    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
    MyModuleStatusFlow.ensure_default
  end

  describe 'GET workflows, #index' do
    it 'Response with correct workflows' do
      hash_body = nil
      get api_v1_workflows_path, headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(MyModuleStatusFlow.all, each_serializer: Api::V1::WorkflowSerializer)
            .to_json
        )['data']
      )
    end
  end

  describe 'GET worflow, #show' do
    it 'When valid request' do
      hash_body = nil
      get api_v1_workflow_path(id: MyModuleStatusFlow.all.first), headers: @valid_headers
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(MyModuleStatusFlow.all.first, serializer: Api::V1::WorkflowSerializer)
            .to_json
        )['data']
      )
    end

    it 'When invalid request, non existing workflow' do
      hash_body = nil
      get api_v1_workflow_path(id: -1), headers: @valid_headers
      expect(response).to have_http_status(404)
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body['errors'][0]).to include('status': 404)
    end
  end
end
