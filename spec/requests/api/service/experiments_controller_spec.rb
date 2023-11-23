# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::Service::ExperimentsController", type: :request do
  before :all do
    @user = create(:user)
    @team = create(:team, :change_user_team, created_by: @user)
    @valid_project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @unaccessible_project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)
    @unaccessible_project.user_assignments.destroy_all

    @experiment = create(:experiment, created_by: @user, last_modified_by: @user, project: @valid_project, created_by: @user)

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'POST clone experiment, #clone' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:action) do
      post(
        api_service_team_clone_experiment_path(team_id: @valid_project.team.id),
        params: request_body.to_json,
        headers: @valid_headers
      )
    end

    context 'when has valid params' do
      let(:request_body) do
        {
          clone_experiment: {
            experiment_id: @experiment.id,
            to_project_id: @valid_project.id
          }
        }
      end

      it 'creates new experiment' do
        expect { action }.to change { Experiment.count }.by(1)
      end

      it 'returns status 200' do
        action
        expect(response).to have_http_status 200
      end
    end

    context 'when has missing param' do
      let(:request_body) do
        {
          clone_experiment: {
            experiment_id: @experiment.id
          }
        }
      end

      it 'renders 400' do
        action

        expect(response).to have_http_status(400)
      end
    end

    context 'when has wrong project' do
      let(:request_body) do
        {
          clone_experiment: {
            experiment_id: @experiment.id,
            to_project_id: @unaccessible_project.id
          }
        }
      end

      it 'renders 403' do
        action

        expect(response).to have_http_status(403)
      end
    end
  end
end
