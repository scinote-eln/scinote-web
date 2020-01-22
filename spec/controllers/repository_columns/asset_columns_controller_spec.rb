# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryColumns::AssetColumnsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:repository) { create :repository, created_by: user, team: team }
  let(:repository_column) { create(:repository_column, :asset_type, repository: repository) }

  describe 'POST repository_asset_columns, #create' do
    let(:action) { post :create, params: params }
    let(:params) do
      {
        repository_id: repository.id,
        repository_column: {
          name: 'name'
        }
      }
    end

    before do
      service = double('success_service')
      allow(service).to(receive(:succeed?)).and_return(true)
      allow(service).to(receive(:column)).and_return(repository_column)

      allow_any_instance_of(RepositoryColumns::CreateColumnService).to(receive(:call)).and_return(service)
    end

    context 'when columnd is created' do
      it 'respons with status 201' do
        action

        expect(response).to(have_http_status(201))
      end
    end

    context 'when repository is not found' do
      let(:params) do
        {
          repository_id: -1,
          repository_column: {
            name: 'name'
          }
        }
      end

      it 'respons with status 404' do
        action

        expect(response).to(have_http_status(404))
      end
    end

    context 'when user does not have permissions' do
      before do
        user_team.role = :guest
        user_team.save
      end

      it 'respons with status 403' do
        action

        expect(response).to(have_http_status(403))
      end
    end

    context 'when column cannot be created' do
      before do
        service = double('failure_service')
        allow(service).to(receive(:succeed?)).and_return(false)
        allow(service).to(receive(:errors)).and_return({})

        allow_any_instance_of(RepositoryColumns::CreateColumnService).to(receive(:call)).and_return(service)
      end

      it 'respons with status 422' do
        action

        expect(response).to(have_http_status(422))
      end
    end
  end

  describe 'PUT repository_status_column, #update' do
    let(:action) { patch :update, params: params }

    let(:params) do
      {
        repository_id: repository.id,
        id: repository_column.id,
        repository_column: {
          name: 'name'
        }
      }
    end

    before do
      service = double('success_service')
      allow(service).to(receive(:succeed?)).and_return(true)
      allow(service).to(receive(:column)).and_return(repository_column)

      allow_any_instance_of(RepositoryColumns::UpdateColumnService).to(receive(:call)).and_return(service)
    end

    context 'when columnd is updated' do
      it 'respons with status 200' do
        action

        expect(response).to(have_http_status(200))
      end
    end

    context 'when column is not found' do
      let(:params) do
        {
          repository_id: repository.id,
          id: -1,
          repository_column: {
            name: 'name'
          }
        }
      end

      it 'respons with status 404' do
        action

        expect(response).to(have_http_status(404))
      end
    end

    context 'when user does not have permissions' do
      before do
        user_team.role = :guest
        user_team.save
      end

      it 'respons with status 403' do
        action

        expect(response).to(have_http_status(403))
      end
    end

    context 'when column cannot be updated' do
      before do
        service = double('failure_service')
        allow(service).to(receive(:succeed?)).and_return(false)
        allow(service).to(receive(:errors)).and_return({})

        allow_any_instance_of(RepositoryColumns::UpdateColumnService).to(receive(:call)).and_return(service)
      end

      it 'respons with status 422' do
        action

        expect(response).to(have_http_status(422))
      end
    end
  end

  describe 'DELETE repository_status_column, #delete' do
    let(:action) { delete :destroy, params: params }

    let(:params) do
      {
        repository_id: repository.id,
        id: repository_column.id
      }
    end

    before do
      service = double('success_service')
      allow(service).to(receive(:succeed?)).and_return(true)

      allow_any_instance_of(RepositoryColumns::DeleteColumnService).to(receive(:call)).and_return(service)
    end

    context 'when column deleted' do
      it 'respons with status 200' do
        action

        expect(response).to(have_http_status(200))
      end
    end

    context 'when column is not found' do
      let(:params) do
        {
          repository_id: repository.id,
          id: -1
        }
      end

      it 'respons with status 404' do
        action

        expect(response).to(have_http_status(404))
      end
    end

    context 'when user does not have permissions' do
      before do
        user_team.role = :guest
        user_team.save
      end

      it 'respons with status 403' do
        action

        expect(response).to(have_http_status(403))
      end
    end

    context 'when column cannot be deleted fails' do
      before do
        service = double('failure_service')
        allow(service).to(receive(:succeed?)).and_return(false)
        allow(service).to(receive(:errors)).and_return({})

        allow_any_instance_of(RepositoryColumns::DeleteColumnService).to(receive(:call)).and_return(service)
      end

      it 'respons with status 422' do
        action

        expect(response).to(have_http_status(422))
      end
    end
  end
end
