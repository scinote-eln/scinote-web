# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ProjectFoldersController', type: :request do
  let(:user) { create :user }
  let(:valid_headers) { { 'Authorization': 'Bearer ' + generate_token(user.id) } }
  let(:team) { create :team, created_by: user }
  let(:project_folder) do
    create :project_folder, team: team
  end

  describe 'GET index' do
    let(:params) { { team_id: team.id } }
    let(:action) { get(api_v1_team_project_folders_path(params), headers: valid_headers) }

    context 'when has valid params' do
      it 'renders 200' do
        action

        expect(response).to have_http_status(200)
        expect(response).to match_json_schema('project_folders/collection')
      end
    end

    context 'when user is not part of the team' do
      let(:second_team) { create :team }
      let(:params) { { team_id: second_team.id } }

      it 'renders 403' do
        action

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'GET show' do
    let(:params) { { team_id: team.id, id: project_folder_id } }
    let(:action) { get(api_v1_team_project_folder_path(params), headers: valid_headers) }
    let(:project_folder_id) { project_folder.id }

    context 'when project_folder found' do
      it do
        action

        expect(response).to have_http_status(200)
        expect(response).to match_json_schema('project_folders/resource')
      end
    end

    context 'when project_folder does not exists' do
      let(:project_folder_id) { -1 }

      it do
        action

        expect(response).to have_http_status 404
      end
    end
  end

  describe 'POST create' do
    let(:params) do
      {
        data: {
          type: 'project_folders',
          attributes: {
            name: project_folder_name,
            parent_folder_id: parent_folder_id
          }
        }
      }
    end
    let(:action) { post(api_v1_team_project_folders_path(team_id: team.id), params: params, headers: valid_headers) }
    let(:project_folder_name) { 'MyNewFolder' }
    let(:parent_folder_id) { nil }

    context 'when project_folder can be created' do
      context 'when root project_folder' do
        it 'creates new project_folder' do
          action

          expect(response).to have_http_status(201)
          expect(response).to match_json_schema('project_folders/resource')
        end
      end

      context 'when nested project_folder' do
        let(:parent_folder_id) { create(:project_folder, team: team).id }

        it 'creates new project_folder inside existing project_folder' do
          action

          expect(response).to have_http_status(201)
          expect(response).to match_json_schema('project_folders/resource')
          expect(JSON.parse(response.body).dig('data', 'relationships', 'parent_folder', 'data')).to be_truthy
        end
      end
    end

    context 'when project_folder cannot be created' do
      context 'when validation error' do
        let(:project_folder_name) { '' }

        it 'should returns validation error' do
          action

          expect(response).to have_http_status 400
          expect(JSON.parse(response.body)['errors'].first['title']).to be_eql 'Validation error'
        end
      end
    end
  end

  describe 'PATCH update' do
    let(:params) do
      {
        data: {
          id: project_folder.id,
          type: 'project_folders',
          attributes: {
            name: project_folder_name,
            parent_folder_id: parent_folder_id
          }
        }
      }
    end
    let(:action) do
      patch(api_v1_team_project_folder_path(team_id: team.id, id: project_folder_id),
            params: params,
            headers: valid_headers)
    end
    let(:project_folder_name) { 'MyUpdatedFolder' }
    let(:project_folder_id) { project_folder.id }
    let(:parent_folder_id) { nil }

    context 'when project_folder can be updated' do
      context 'when root project_folder' do
        it 'updates project_folder' do
          action

          expect(response).to have_http_status(200)
          expect(response).to match_json_schema('project_folders/resource')
        end
      end

      context 'when update parent project_folder' do
        let(:parent_folder_id) { create(:project_folder, team: team).id }

        it 'updates project_folder\'s parent with existing project_folder' do
          action

          expect(JSON.parse(response.body).dig('data', 'relationships', 'parent_folder', 'data')).to be_truthy
          expect(response).to have_http_status(200)
        end
      end

      context 'when nothing to update' do
        let(:project_folder_name) { project_folder.name }

        it 'do not update project_folder, returns 204' do
          action

          expect(response).to have_http_status(204)
        end
      end
    end

    context 'when project_folder cannot be updated' do
      context 'when validation error' do
        let(:project_folder_name) { '' }

        it 'returns validation error, returns 400' do
          action

          expect(response).to have_http_status(400)
          expect(JSON.parse(response.body)['errors'].first['title']).to be_eql 'Validation error'
        end
      end

      context 'when parent_folder belongs to another team' do
        let(:folder_from_another_team) { create(:project_folder) }
        let(:parent_folder_id) { folder_from_another_team.id }

        it do
          action

          expect(JSON.parse(response.body)['errors'].first['title']).to be_eql 'Validation error'
          expect(response).to have_http_status 400
        end
      end

      context 'when mismatch IDs' do
        let(:project_folder_id) { create(:project_folder, team: team).id }

        it '' do
          action

          expect(response).to have_http_status(400)
          expect(JSON.parse(response.body)['errors'].first['title']).to be_eql 'Object ID mismatch'
        end
      end
    end
  end
end
