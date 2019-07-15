# frozen_string_literal: true

require 'rails_helper'

describe TeamRepositoriesController, type: :controller do
  login_user

  let(:user) { controller.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:repository) { create :repository, team: team }
  let(:target_team) { create :team }

  describe 'POST create' do
    context 'when resource can be saved' do
      it 'renders 200' do
        post :create,
             params: { team_id: team.id,
                       repository_id: repository.id,
                       target_team_id: target_team.id,
                       permission_level: 'read' },
             format: :json

        expect(response).to have_http_status(200)
      end
    end

    context 'when resource cannot be saved' do
      it 'renders 304' do
        post :create,
             params: { team_id: team.id, repository_id: repository.id, target_team_id: -1 },
             format: :json

        expect(response).to have_http_status(422)
      end
    end

    context 'when user do not have permissions' do
      let(:new_repository) { create :repository }

      it 'renders 403' do
        post :create,
             params: { team_id: team.id, repository_id: new_repository.id },
             format: :json

        expect(response).to have_http_status(403)
      end
    end

    context 'when repository is not found' do
      it 'renders 404' do
        post :create,
             params: { team_id: team.id, repository_id: -1, target_team_id: 'id' },
             format: :json

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE destroy' do
    let(:team_repository) { create :team_repository, :read, team: team, repository: repository }

    context 'when resource can be deleted' do
      it 'renders 204' do
        delete :destroy, params: { repository_id: repository.id, team_id: team.id, id: team_repository.id }

        expect(response).to have_http_status(204)
      end
    end

    context 'when user do not have permissions' do
      let(:new_repository) { create :repository }

      it 'renders 403' do
        delete :destroy, params: { repository_id: new_repository.id, team_id: team.id, id: team_repository.id }

        expect(response).to have_http_status(403)
      end
    end
  end
end
