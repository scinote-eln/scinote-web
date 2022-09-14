# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TablesController', type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, team: @team, created_by: @user)
    @experiment = create(:experiment, :with_tasks, project: @project, created_by: @user)
    @task = @experiment.my_modules.first
    @protocol = create(:protocol, my_module: @task)
    @step = create(:step, protocol: @protocol)

    @valid_headers = {
      'Authorization': 'Bearer ' + generate_token(@user.id),
      'Content-Type': 'application/json'
    }
  end

  describe 'GET tables, #index' do
    context 'when has valid params' do
      it 'renders 200' do
        get api_v1_team_project_experiment_task_protocol_step_tables_path(
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
        get api_v1_team_project_experiment_task_protocol_step_tables_path(
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

  describe 'GET table, #show' do
    let(:table) { create(:table, step: @step) }

    context 'when has valid params' do
      it 'renders 200' do
        get api_v1_team_project_experiment_task_protocol_step_table_path(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @task.id,
          protocol_id: @protocol.id,
          step_id: @step.id,
          id: table.id
        ), headers: @valid_headers

        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST table, #create' do
    let(:action) do
      post(api_v1_team_project_experiment_task_protocol_step_tables_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id
      ), params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {
              name: 'New table',
              contents: '{"data": [["group/time", "1 dpi", "6 dpi", "", ""], ["PVYNTN", "1", "1", "", ""]]}'
            }
          }
        }
      end

      it 'creates new table' do
        expect { action }.to change { Table.count }.by(1)
      end

      it 'returns status 201' do
        action

        expect(response).to have_http_status 201
      end

      it 'returns well formated response' do
        action

        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'tables',
              attributes: hash_including(name: 'New table')
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {
            }
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end

  describe 'PATCH table, #update' do
    let(:table) { create(:table, step: @step) }
    let(:action) do
      patch(api_v1_team_project_experiment_task_protocol_step_table_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        id: table.id
      ), params: request_body.to_json, headers: @valid_headers)
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {
              name: 'New table name',
              contents: '{"data": [["group/time", "2 dpi", "7 dpi", "", ""], ["PVYNTN", "2", "2", "", ""]]}'
            }
          }
        }
      end

      it 'returns status 200' do
        action

        expect(response).to have_http_status 200
      end

      it 'returns well formated response' do
        action

        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'tables',
              attributes: hash_including(
                name: 'New table name',
                contents: '{"data": [["group/time", "2 dpi", "7 dpi", "", ""], ["PVYNTN", "2", "2", "", ""]]}'
              )
            )
          )
        )
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          data: {
            type: 'tables',
            attributes: {
            }
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end
  end

  describe 'DELETE table, #destroy' do
    let(:table) { create(:table, step: @step) }
    let(:action) do
      delete(api_v1_team_project_experiment_task_protocol_step_table_path(
        team_id: @team.id,
        project_id: @project.id,
        experiment_id: @experiment.id,
        task_id: @task.id,
        protocol_id: @protocol.id,
        step_id: @step.id,
        id: table.id
      ), headers: @valid_headers)
    end

    it 'deletes table' do
      action
      expect(response).to have_http_status(200)
      expect(Table.where(id: table.id)).to_not exist
    end
  end
end
