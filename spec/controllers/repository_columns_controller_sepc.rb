# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumnsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:repository) { create :repository, created_by: user, team: team }
  let(:repository_column) do
    create :repository_column, created_by: user, repository: repository
  end

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      {
        repository_id: repository.id,
        repository_column: {
          name: 'repository_column',
          data_type: 'RepositoryTextValue'
        }
      }
    end

    it 'calls create activity for creating inventory column' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :create_column_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      {
        id: repository_column.id,
        repository_id: repository.id,
        repository_column: {
          name: 'new_repository_column'
        }
      }
    end

    it 'calls create activity for editing intentory column' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :edit_column_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params, format: :json }
    let(:params) do
      { repository_id: repository.id, id: repository_column.id }
    end

    it 'calls create activity for deleting inventory items' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_column_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
