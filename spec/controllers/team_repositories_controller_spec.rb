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
      let(:action) do
        post :create,
             params: { team_id: team.id,
                       repository_id: repository.id,
                       target_team_id: target_team.id,
                       permission_level: 'read' },
             format: :json
      end
      it 'renders 200' do
        action

        expect(response).to have_http_status(200)
      end

      it 'calls create activity for deleting inventory' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :share_inventory)))

        action
      end

      it 'adds activity in DB' do
        expect { action }.to(change { Activity.count })
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
    let(:second_team) { create :team }
    let!(:second_user_team) { create :user_team, user: user, team: second_team }
    let(:team_repository) { create :team_repository, :read, team: second_team, repository: repository }

    context 'when resource can be deleted' do
      let(:action) do
        delete :destroy, params: { repository_id: repository.id, team_id: team.id, id: team_repository.id }
      end

      it 'renders 204' do
        action

        expect(response).to have_http_status(204)
      end

      it 'calls create activity for deleting inventory' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :unshare_inventory)))

        action
      end

      it 'adds activity in DB' do
        expect { action }.to(change { Activity.count })
      end
    end

    context 'when resource is not found' do
      it 'renders 422' do
        delete :destroy, params: { repository_id: repository.id, team_id: team.id, id: -1 }

        expect(response).to have_http_status(422)
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

  describe 'POST multiple_update' do
    context 'when have valid params' do
      before do
        service = double('success_service')
        allow(service).to(receive(:succeed?)).and_return(true)
        allow(service).to(receive(:warnings)).and_return([])

        allow_any_instance_of(Repositories::MultipleShareUpdateService).to(receive(:call)).and_return(service)
      end

      let(:params) do
        {
          repository_id: repository.id,
          team_id: team.id,
          permission_changes: '{"5":true}',
          share_team_ids: %w(1 2 3),
          write_permissions: %w(3)
        }
      end

      it 'renders status ok' do
        post :multiple_update, params: params

        expect(response).to have_http_status(200)
      end
    end

    context 'when have invalid params' do
      before do
        service = double('unsuccess_service')
        allow(service).to(receive(:succeed?)).and_return(false)
        allow(service).to(receive(:errors)).and_return({})

        allow_any_instance_of(Repositories::MultipleShareUpdateService).to(receive(:call)).and_return(service)
      end

      let(:new_repository) { create :repository }
      let(:params) do
        {
          repository_id: new_repository.id,
          team_id: team.id,
          permission_changes: '{"5":true}',
          share_team_ids: %w(1 2 3),
          write_permissions: %w(3)
        }
      end

      it 'renders status 422' do
        post :multiple_update, params: params

        expect(response).to have_http_status(422)
      end
    end
  end
end
