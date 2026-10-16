# frozen_string_literal: true

require 'rails_helper'

describe UserRepositoriesController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, created_by: user, team: team }

  describe 'POST save_table_state' do
    let(:state) { { length: '25', order: { '0' => { '0' => '2', '1' => 'asc' } } } }

    it 'stores the state for the current user' do
      post :save_table_state, params: { repository_id: repository.id, state: state }, format: :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['status']).to eq 'ok'
      saved = RepositoryTableState.find_by(user: user, repository: repository)
      expect(saved.state['length']).to eq '25'
    end

    it 'falls back to the default order when the order column is below 1' do
      post :save_table_state,
           params: { repository_id: repository.id, state: { length: '10', order: { '0' => { '0' => '0', '1' => 'asc' } } } },
           format: :json

      saved = RepositoryTableState.find_by(user: user, repository: repository)
      expect(saved.state['order']).to eq repository.default_table_state['order'].as_json
    end

    it 'is forbidden for a repository the user cannot read' do
      other_repository = create :repository
      post :save_table_state, params: { repository_id: other_repository.id, state: state }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(RepositoryTableState.where(repository: other_repository)).to be_empty
    end

    it 'is forbidden for a missing repository' do
      post :save_table_state, params: { repository_id: 0, state: state }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST load_table_state' do
    it 'returns the default state when nothing is stored' do
      post :load_table_state, params: { repository_id: repository.id }, format: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['state']['length'].to_i).to be_positive
      expect(body['state']['columns']).to be_present
      expect(RepositoryTableState.where(user: user, repository: repository).count).to eq 1
    end

    it 'is forbidden for a repository the user cannot read' do
      other_repository = create :repository
      post :load_table_state, params: { repository_id: other_repository.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
