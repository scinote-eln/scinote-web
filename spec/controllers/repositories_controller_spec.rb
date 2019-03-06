# frozen_string_literal: true

require 'rails_helper'

describe RepositoriesController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }

  describe 'POST create' do
    let(:params) { { repository: { name: 'My Repository' } } }

    it 'calls create activity for unarchiving experiment' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :create_inventory)))

      post :create, params: params, format: :json
    end
  end

  describe 'DELETE destroy' do
    let(:repository) { create :repository, team: team }
    let(:params) { { id: repository.id, team_id: team.id } }

    it 'calls create activity for unarchiving experiment' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_inventory)))

      delete :destroy, params: params
    end
  end

  describe 'PUT update' do
    let(:repository) { create :repository, team: team }
    let(:params) do
      { id: repository.id, team_id: team.id, repository: { name: 'new_name' } }
    end

    it 'calls create activity for unarchiving experiment' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :rename_inventory)))

      put :update, params: params, format: :json
    end
  end
end
