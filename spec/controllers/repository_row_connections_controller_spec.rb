# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRowConnectionsController, type: :controller do
  login_user
  render_views
  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, team: team, created_by: user }
  let!(:other_repository) { create :repository, team: team, created_by: user }
  let!(:repository_row) { create :repository_row, repository: repository, created_by: user }
  let!(:other_repository_row) { create :repository_row, repository: repository, created_by: user }

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:create_params) do
        {
          repository_id: repository.id,
          repository_row_id: repository_row.id,
          repository_row_connection: {
            connection_repository_id: repository.id,
            relation: 'parent',
            relation_ids: [other_repository_row.id]
          }
        }
      end

      it 'creates a new connection' do
        expect {
          post :create, params: create_params, format: :json
        }.to change(RepositoryRowConnection, :count).by(1)
      end

      it 'returns a success response' do
        post :create, params: create_params, format: :json
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:connection) { create(:repository_row_connection, parent: repository_row, child: other_repository_row, created_by: user, last_modified_by: user) }

    it 'destroys the connection' do
      expect {
        delete :destroy, params: { repository_id: repository.id, repository_row_id: repository_row.id, id: connection.id }, format: :json
      }.to change(RepositoryRowConnection, :count).by(-1)
    end

    it 'returns a no content status' do
      delete :destroy, params: { repository_id: repository.id, repository_row_id: repository_row.id, id: connection.id }, format: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'GET #repositories' do
    it 'returns a successful response' do
      get :repositories, format: :json
      expect(response).to have_http_status(:success)
    end

    it 'returns the correct data structure' do
      get :repositories, format: :json
      expect(response.body).to include(repository.name)
    end
  end

  describe 'GET #repository_rows' do
    let!(:child_repository_row) { create :repository_row, repository: repository }
    let!(:parent_repository_row) { create :repository_row, repository: repository }

    let!(:child_connection) do
      create :repository_row_connection,
             parent: repository_row,
             child: child_repository_row,
             created_by: user,
             last_modified_by: user
    end
    let!(:parent_connection) do
      create :repository_row_connection,
             child: repository_row,
             parent: parent_repository_row,
             created_by: user,
             last_modified_by: user
    end

    it 'returns a successful response' do
      get :repository_rows, format: :json, params: {
        repository_id: repository.id,
        repository_row_id: repository_row.id,
        selected_repository_id: repository.id
      }
      expect(response).to have_http_status(:success)
    end

    it 'returns the correct data structure' do
      get :repository_rows, format: :json, params: {
        repository_id: repository.id,
        repository_row_id: repository_row.id,
        selected_repository_id: repository.id
      }

      expect(response.body).not_to include(repository_row.name)
      expect(response.body).not_to include(child_repository_row.name)
      expect(response.body).not_to include(parent_repository_row.name)
      expect(response.body).to include(other_repository_row.name)
    end
  end
end
