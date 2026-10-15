# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumns::NumberColumnsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }

  def make_viewer
    UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
  end

  describe 'POST create' do
    let(:params) { { repository_id: repository.id, repository_column: { name: 'Weight', metadata: { decimals: 3 } } } }

    it 'creates a number column and logs an activity' do
      expect(Activities::CreateActivityService)
        .to receive(:call).with(hash_including(activity_type: :create_column_inventory))

      expect { post :create, params: params, format: :json }.to change(RepositoryColumn, :count).by(1)

      expect(response).to have_http_status(:created)
      column = repository.repository_columns.find_by(name: 'Weight')
      expect(column.data_type).to eq 'RepositoryNumberValue'
      expect(column.metadata['decimals'].to_s).to eq '3'
      expect(column.created_by).to eq user
    end

    it 'returns validation errors for a duplicate name' do
      create :repository_column, name: 'Weight', repository: repository, created_by: user

      expect { post :create, params: params, format: :json }.not_to change(RepositoryColumn, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['repository_column']).to have_key('name')
    end

    it 'is forbidden for a viewer' do
      make_viewer
      expect { post :create, params: params, format: :json }.not_to change(RepositoryColumn, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns not found for an unknown repository' do
      post :create, params: params.merge(repository_id: 0), format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT update' do
    let!(:column) do
      create :repository_column, name: 'Old', data_type: :RepositoryNumberValue, repository: repository,
                                 created_by: user, metadata: { decimals: 1 }
    end
    let(:params) do
      { repository_id: repository.id, id: column.id, repository_column: { name: 'New', metadata: { decimals: 4 } } }
    end

    it 'updates the column and logs an activity' do
      expect(Activities::CreateActivityService)
        .to receive(:call).with(hash_including(activity_type: :edit_column_inventory))

      put :update, params: params, format: :json

      expect(response).to have_http_status(:ok)
      column.reload
      expect(column.name).to eq 'New'
      expect(column.metadata['decimals'].to_s).to eq '4'
    end

    it 'returns validation errors for a blank name' do
      params[:repository_column][:name] = ''

      put :update, params: params, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['repository_column']).to have_key('name')
      expect(column.reload.name).to eq 'Old'
    end

    it 'returns not found for an unknown column' do
      put :update, params: params.merge(id: 0), format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for a viewer' do
      make_viewer
      put :update, params: params, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(column.reload.name).to eq 'Old'
    end
  end
end
