# frozen_string_literal: true

require 'rails_helper'

describe UserRepositoriesController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, created_by: user, team: team }

  describe 'POST save_table_state' do
    let(:state) { { length: '25', order: { '0' => { '0' => '2', '1' => 'asc' } } } }

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

    it 'is forbidden for a repository the user cannot read' do
      other_repository = create :repository
      post :load_table_state, params: { repository_id: other_repository.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
