# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::StepElements::FormResponsesController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, team: @team, created_by: @user)
    @experiment = create(:experiment, :with_tasks, project: @project, created_by: @user)
    @task = @experiment.my_modules.first
    @protocol = create(:protocol, my_module: @task)
    @step = create(:step, protocol: @protocol)
    @form = create(:form, team: @team, created_by: @user)
    @form_field = create(:form_field, form: @form, created_by: @user, data: { type: 'TextField' })
    @form_response = create(:form_response, form: @form, parent: @step, created_by: @user)
    @form_field_value = create(:form_field_value, type: 'FormTextFieldValue', form_field: @form_field, form_response: @form_response, created_by: @user)

    @valid_headers = {
      'Authorization': 'Bearer ' + generate_token(@user.id),
      'Content-Type': 'application/json'
    }
  end

  describe 'GET form_responses, #index' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_step_form_responses_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end

    context 'when step is not found' do
      it 'renders 404' do
        get api_v2_team_project_experiment_task_protocol_step_form_responses_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: -1
        ), headers: @valid_headers

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET form_response, #show' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v2_team_project_experiment_task_protocol_step_form_response_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id,
          id: @form_response.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end
  end
end
