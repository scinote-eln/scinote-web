# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::Service::ProjectsJsonExportController", type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, created_by: @user)

    @accessible_project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @accessible_experiment = create(:experiment, created_by: @user,
                               last_modified_by: @user, project: @accessible_project)
    @unaccessible_experiment = create(:experiment, created_by: @user,
                                      last_modified_by: @user, project: @accessible_project)
    @accessible_task = create(:my_module, :with_due_date, created_by: @user,
                              last_modified_by: @user, experiment: @accessible_experiment)

    @unaccessible_task = create(:my_module, :with_due_date, created_by: @user,
                                last_modified_by: @user, experiment: @unaccessible_experiment)
      
    @unaccessible_experiment.user_assignments.destroy_all

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'POST get projects json export, #projects_json_export' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:request_body) do
      {
        data: {
          "callback_url": Faker::Internet.url,
          "task_ids": [@accessible_task.id, @unaccessible_task.id]
        }
      }
    end

    let(:action) do
      post(
        api_service_projects_json_export_path,
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      it 'returns status 202' do
        action
        expect(response).to have_http_status 202
      end
    end

    context 'when has invalid params' do
      it 'Missing task_ids parameter' do
        request_body[:data].delete(:task_ids)
        action
        expect(response).to have_http_status 400
      end

      it 'Missing callback_url parameter' do
        request_body[:data].delete(:callback_url)
        action
        expect(response).to have_http_status 400
      end

      it 'Invalid callback url' do
        request_body[:data][:callback_url] = Faker::Name.unique.name
        action
        expect(response).to have_http_status 400
      end
    end
  end
end
