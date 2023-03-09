# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryColumns::TextColumnsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, created_by: user, team: team }
  let(:repository_column) { create(:repository_column, :text_type, repository: repository) }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:viewer_role) { create :viewer_role }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }

  describe 'POST repository_text_columns, #create' do
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

    context 'when column is created' do
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
        repository.user_assignments.update(user_role: viewer_role)
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

  describe 'PUT repository_text_column, #update' do
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

    context 'when column is updated' do
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
        repository.user_assignments.update(user_role: viewer_role)
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
end
