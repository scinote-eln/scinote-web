# frozen_string_literal: true

require 'rails_helper'

describe RepositoriesController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:action) { post :create, params: params, format: :json }

  describe 'POST create' do
    let(:params) { { repository: { name: 'My Repository' } } }

    it 'calls create activity for unarchiving experiment' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :create_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE destroy' do
    let(:repository) { create :repository, team: team }
    let(:params) { { id: repository.id, team_id: team.id } }
    let(:action) { delete :destroy, params: params }

    it 'calls create activity for unarchiving experiment' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:repository) { create :repository, team: team }
    let(:params) do
      { id: repository.id, team_id: team.id, repository: { name: 'new_name' } }
    end
    let(:action) { put :update, params: params, format: :json }

    it 'calls create activity for unarchiving experiment' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :rename_inventory)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST export_repository' do
    let(:repository) { create :repository, team: team }
    let(:repository_row) { create :repository_row, repository: repository }
    let(:repository_column) do
      create :repository_column, repository: repository
    end
    let(:repository_cell) do
      create :repository_cell,
             repository_row: repository_row,
             repository_column: repository_column
    end
    let(:params) do
      {
        id: repository.id,
        header_ids: [repository_column.id],
        row_ids: [repository_row.id]
      }
    end
    let(:action) { post :export_repository, params: params, format: :json }

    it 'calls create activity for unarchiving experiment' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :export_inventory_items)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
