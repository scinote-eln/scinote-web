# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TaskAssignmentsController', type: :request do
  before :all do
    @user = create(:user)
    @user_second = create(:user)
    @team = create(:team, created_by: @user)
    @owner_role = UserRole.find_by(name: I18n.t('user_roles.predefined.owner'))
    @project = create(:project, name: Faker::Name.unique.name,
                      created_by: @user, team: @team)

    @experiment = create(:experiment, created_by: @user,
      last_modified_by: @user, project: @project)

    @my_module = create(
      :my_module,
      :with_due_date,
      created_by: @user,
      last_modified_by: @user,
      experiment: @experiment
    )

    @UserMyModule = create(
      :user_my_module,
      my_module: @my_module, 
      user: @user
    )

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET assigned users on task, #index' do
    it 'Response with correct task inventory items' do
      hash_body = nil
      get api_v1_team_project_experiment_task_task_assignments_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @my_module.id
        ), headers: @valid_headers
      
      expect(response).to have_http_status 200
      expect { hash_body = json }.not_to raise_exception
      expect(hash_body[:data]).to match(
        [JSON.parse(
          serialized_user = ActiveModelSerializers::SerializableResource
            .new(@user, serializer: Api::V1::UserSerializer)
            .to_json
        )['data']]
      )
    end
  end

  describe 'CREATE assign user to task, #create' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:request_body_valid) do
      {
        data: {
          type: 'task_assignments',
          attributes: {
            user_id: @user_second.id
          }
        }
      }
    end

    let(:request_body_existing) do
      {
        data: {
          type: 'task_assignments',
          attributes: {
            user_id: @user.id
          }
        }
      }
    end

    context 'when has valid params' do
      let(:action) do
        post(api_v1_team_project_experiment_task_task_assignments_path(
               team_id: @team.id,
               project_id: @project.id,
               experiment_id: @experiment.id,
               task_id: @my_module.id
             ),
             params: request_body_valid.to_json,
             headers: @valid_headers)
      end

      it 'Count assigned users' do
        action
        expect(@my_module.user_my_modules.count).to eq(2)
      end

      it 'returns well formated response' do
        action
        expect(json[:data]).to match(
          JSON.parse(
            ActiveModelSerializers::SerializableResource
              .new(UserMyModule.last,
                   serializer: Api::V1::TaskAssignmentSerializer)
              .to_json
          )['data']
        )
      end
    end

    context 'when has not valid params' do
      let(:action) do
        post(api_v1_team_project_experiment_task_task_assignments_path(
               team_id: @team.id,
               project_id: @project.id,
               experiment_id: @experiment.id,
               task_id: @my_module.id
             ),
             params: request_body_existing.to_json,
             headers: @valid_headers)
      end

      it 'User already assigned to task' do
        action
        expect(response).to have_http_status 400
        expect(@my_module.user_my_modules.count).to eq(1)
      end
    end
  end

  describe 'DELETE assigned user to task, #destroy' do
    it 'Delete assigned item' do
      delete(api_v1_team_project_experiment_task_task_assignment_path(
              id: @user.id,
              team_id: @team.id,
              project_id: @project.id,
              experiment_id: @experiment.id,
              task_id: @my_module.id
            ), 
            headers: @valid_headers)
      expect(response).to have_http_status(200)
      expect(@my_module.user_my_modules.count).to eq(0)
    end

    it 'Delete assigned item' do
      delete(api_v1_team_project_experiment_task_task_assignment_path(
              id: @user_second.id,
              team_id: @team.id,
              project_id: @project.id,
              experiment_id: @experiment.id,
              task_id: @my_module.id
            ),
            headers: @valid_headers)
      expect(response).to have_http_status(404)
      expect(@my_module.user_my_modules.count).to eq(1)
    end
  end
end
