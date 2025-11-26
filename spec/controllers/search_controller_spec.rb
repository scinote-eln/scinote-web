# frozen_string_literal: true

require 'rails_helper'

describe SearchController, type: :controller do
  login_user
  include_context 'reference_project_structure', {
      # result_text: true
    }

  describe 'GET index' do
    let(:action) { get :index, params: params, format: :json }

    context 'search projects' do
      let(:params) {{ q: project.name, group: 'projects' }}
      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'search project_folders' do
      let(:project_folder) { create :project_folder, team: team }
      let(:params) {{ q: project_folder.name, group: 'project_folders' }}
      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'search reports' do
      let(:report) do
        create :report, user: user, project: project, team: team,
                        name: 'test repot A2', description: 'test description A1'
      end
      let(:params) {{ q: report.name, group: 'reports' }}
      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'search module_protocols' do
      let(:protocol) { my_module.protocol }
      let(:params) {{ q: 'test protocol', group: 'module_protocols' }}
      it 'correct JSON format' do
        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(0)
      end
    end

    context 'search experiments' do
      let(:params) {{ q: experiment.name, group: 'experiments' }}
      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'search tasks' do
      let(:params) {{ q: my_module.name, group: 'tasks' }}
      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'search results' do
      let(:result) { create :result, my_module: my_module, user: user }
      let(:params) {{ q: result.name, group: 'results' }}
      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'search protocols' do
      let(:protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }
      let(:params) {{ q: protocol.name, group: 'protocols' }}
      it 'correct JSON format' do
        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'search label_templates' do
      let(:params) {{ q: 'random name', group: 'label_templates' }}
      it 'correct JSON format' do
        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(0)
      end
    end

    context 'search repository_rows' do
      let(:repository) { create :repository, created_by: user, team: team }
      let(:repository_row) { create :repository_row, created_by: user, repository: repository }
      let(:params) {{ q: repository_row.name, group: 'repository_rows' }}

      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'search assets' do
      let(:params) {{ q: 'random name', group: 'assets' }}
      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(0)
      end
    end

    context 'filter by user projects' do
      let(:params) { { q: project.name, group: 'projects', filters: { users: { 0 => user.id } } } }
      it 'correct JSON format' do
        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(0)
      end
    end

    context 'filter by user tasks' do
      let(:params) { { q: project.name, group: 'tasks', filters: { users: { 0 => user.id } } } }
      it 'correct JSON format' do
        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(0)
      end
    end

    context 'filter by created_at on projects' do
      let(:params) { { q: project.name, group: 'projects', filters: { created_at: { 'on' => Time.current.utc.beginning_of_day } } } }
      it 'correct JSON format' do
        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end
  end

  describe 'GET quick' do
    let(:action) { get :quick, params: params, format: :json }

    context 'without filter params' do
      let(:params) { { query: project.name } }
      it 'correct JSON format' do

        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end

    context 'with filter param' do
      let(:params) { {  query: project.name, filter: 'project' } }
      it 'correct JSON format with params' do
        action  
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['data'].count).to eq(1)
      end
    end
  end
end
