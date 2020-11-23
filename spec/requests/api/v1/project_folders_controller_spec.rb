# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ProjectFoldersController', type: :request do
  let(:user) { create :user }
  let(:valid_headers) { { 'Authorization': 'Bearer ' + generate_token(user.id) } }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, team: team, user: user }
  let(:folder) do
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
    let(:params) { { team_id: team.id, id: folder_id } }
    let(:action) { get(api_v1_team_project_folder_path(params), headers: valid_headers) }
    let(:folder_id) { folder.id }

    context 'when project_folder found' do
      it do
        action

        expect(response).to have_http_status(200)
        expect(response).to match_json_schema('project_folders/resource')
      end
    end

    context 'when project_folder does not exists' do
      let(:folder_id) { -1 }

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
            name: folder_name,
            parent_folder_id: parent_folder_id
          }
        }
      }
    end
    let(:action) { post(api_v1_team_project_folders_path(team_id: team.id), params: params, headers: valid_headers) }
    let(:folder_name) { 'MyNewFolder' }
    let(:parent_folder_id) { nil }

    context 'when folder can be created' do
      context 'when root folder' do
        it 'creates new folder' do
          action

          expect(response).to have_http_status(201)
          expect(response).to match_json_schema('project_folders/resource')
        end
      end

      context 'when nested folder' do
        let(:parent_folder_id) { create(:project_folder, team: team).id }

        it 'creates new folder inside existing folder' do
          action

          expect(response).to have_http_status(201)
          expect(response).to match_json_schema('project_folders/resource')
        end
      end
    end

    context 'when folder cannot be created' do
      context 'when validation error' do
        let(:folder_name) { '' }

        it 'should returns validation error' do
          action

          expect(response).to have_http_status 400
          expect(JSON.parse(response.body)['errors'].first['title']).to be_eql 'Validation error'
        end
      end

      context 'when parent_folder not found' do
        let(:parent_folder_id) { -1 }

        it do
          action

          expect(response).to have_http_status 404
        end
      end
    end
  end

  describe 'PATCH update' do
    let(:params) do
      {
        data: {
          id: folder.id,
          type: 'project_folders',
          attributes: {
            name: folder_name,
            parent_folder_id: parent_folder_id
          }
        }
      }
    end
    let(:action) do
      patch(api_v1_team_project_folder_path(team_id: team.id, id: folder_id), params: params, headers: valid_headers)
    end
    let(:folder_name) { 'MyUpdatedFolder' }
    let(:folder_id) { folder.id }
    let(:parent_folder_id) { nil }

    context 'when folder can be updated' do
      context 'when root folder' do
        it 'updates folder' do
          action

          expect(response).to have_http_status(200)
          expect(response).to match_json_schema('project_folders/resource')
        end
      end

      context 'when update parent folder' do
        let(:parent_folder_id) { create(:project_folder, team: team).id }

        it 'updates folder\'s parent with existing folder' do
          action

          expect(response).to have_http_status(200)
        end
      end

      context 'when nothing to update' do
        let(:folder_name) { folder.name }

        it 'do not update folder, returns 204' do
          action

          expect(response).to have_http_status(204)
        end
      end
    end

    context 'when folder cannot be updated' do
      context 'when validation error' do
        let(:folder_name) { '' }

        it 'returns validation error, returns 400' do
          action

          expect(response).to have_http_status(400)
          expect(JSON.parse(response.body)['errors'].first['title']).to be_eql 'Validation error'
        end
      end

      context 'when parent_folder not found' do
        let(:parent_folder_id) { -1 }

        it do
          action

          expect(response).to have_http_status(404)
        end
      end

      context 'when mismatch IDs' do
        let(:folder_id) { create(:project_folder, team: team).id }

        it '' do
          action

          expect(response).to have_http_status(400)
          expect(JSON.parse(response.body)['errors'].first['title']).to be_eql 'Object ID mismatch'
        end
      end
    end
  end
end
