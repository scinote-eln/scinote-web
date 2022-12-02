# frozen_string_literal: true

require 'rails_helper'

describe RepositoriesController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let(:action) { post :create, params: params, format: :json }

  describe 'index' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:action) { get :index, format: :json }

    it 'correct JSON format' do
      repository
      action
      parsed_response = JSON.parse(response.body)
      expect(parsed_response[0].keys).to contain_exactly(
        'DT_RowId', '1', '2', '3', '4', '5', '6', '7', '8', 'repositoryUrl', 'DT_RowAttr'
      )
    end
  end

  describe 'POST create' do
    let(:params) { { repository: { name: 'My Repository' } } }

    it 'calls create activity for creating inventory' do
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
    let(:repository) { create :repository, team: team, created_by: user }
    let(:params) { { id: repository.id, team_id: team.id } }
    let(:action) { delete :destroy, params: params }

    it 'calls create activity for deleting inventory' do
      repository.archive!(user)
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :delete_inventory)))

      action
    end

    it 'adds activity in DB' do
      repository.archive!(user)
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:params) do
      { id: repository.id, team_id: team.id, repository: { name: 'new_name' } }
    end
    let(:action) { put :update, params: params, format: :json }

    it 'calls create activity for renaming inventory' do
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
    let(:repository) { create :repository, team: team, created_by: user }
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

    it 'calls create activity for exporting inventory items' do
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

  describe 'POST import_records' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:mappings) do
      { '0': '-1', '1': '', '2': '', '3': '', '4': '', '5': '' }
    end
    let(:params) do
      { id: repository.id,
        team_id: team.id,
        file_id: 'file_id',
        mappings: mappings }
    end
    let(:action) { post :import_records, params: params, format: :json }

    it 'calls create activity for importing inventory items' do
      allow_any_instance_of(ImportRepository::ImportRecords)
        .to receive(:import!).and_return(status: :ok)

      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :import_inventory_items)))

      action
    end

    it 'adds activity in DB' do
      allow_any_instance_of(ImportRepository::ImportRecords).to receive(:import!).and_return(status: :ok)

      expect { action }
        .to(change { Activity.count })
    end
  end
end
