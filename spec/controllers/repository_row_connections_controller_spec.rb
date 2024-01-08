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

  describe '#index' do
    it 'results in unsuccessful response with non-existing repository_id' do
      get :index, format: :json, params: { repository_id: -1, repository_row_id: repository_row.id }
      expect(response).to have_http_status(:not_found)
    end

    it 'results in unsuccessful response with non-existing repository_row_id' do
      get :index, format: :json, params: { repository_id: other_repository.id, repository_row_id: repository_row.id }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns a successful response with valid repository and repository_row' do
      get :index, format: :json, params: { repository_id: repository.id, repository_row_id: repository_row.id }
      expect(response).to have_http_status(:success)
    end

    context 'with valid params' do
      context 'with no connections' do
        it 'returns the correct json response' do
          get :index, format: :json, params: { repository_id: repository.id, repository_row_id: repository_row.id }
          expect(response.body).to eq({ parents: [], children: [] }.to_json)
        end
      end
      
      context 'with some connections' do
        let!(:child_repository_row) { create :repository_row, name: 'child' }
        let!(:parent_repository_row) { create :repository_row, name: 'parent' }

        let!(:child_connection) { create :repository_row_connection,
                                        parent: repository_row,
                                        child: child_repository_row,
                                        created_by: user,
                                        last_modified_by: user }
        let!(:parent_connection) { create :repository_row_connection,
                                         child: repository_row,
                                         parent: parent_repository_row,
                                         created_by: user,
                                         last_modified_by: user }

        it 'returns the correct json response' do
          get :index, format: :json, params: { repository_id: repository.id, repository_row_id: repository_row.id }
          expect(response.body).to eq({ parents: [{
                                                    id: parent_connection.id,
                                                    name: parent_repository_row.name,
                                                    code: "#{RepositoryRow::ID_PREFIX}#{parent_repository_row.id}"
                                                  }],
                                        children: [{
                                                     id: child_connection.id,
                                                     name: child_repository_row.name,
                                                     code: "#{RepositoryRow::ID_PREFIX}#{child_repository_row.id}"
                                                  }] }.to_json)
        end
      end
    end
  end

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
    it 'returns a successful response' do
      get :repository_rows, format: :json, params: {
        repository_id: repository.id, repository_row_id: repository_row.id, selected_repository_id: repository.id
      }
    end

    it 'returns the correct data structure' do
      get :repository_rows, format: :json, params: {
        repository_id: repository.id, repository_row_id: repository_row.id, selected_repository_id: repository.id
      }
      expect(response.body).to include(other_repository_row.name)
    end
  end
end
