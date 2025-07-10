# frozen_string_literal: true

require 'rails_helper'

describe RepositoriesController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let(:action) { post :create, params: params, format: :json }
  let(:repository_template) { create :repository_template, team: team }

  describe 'index' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:action) { get :index, format: :json, params: { page: 1, per_page: 20 } }

    it 'correct JSON format' do
      repository

      action

      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'][0].keys).to contain_exactly(
        'id', 'type', 'attributes'
      )
      expect(parsed_response['data'][0]['attributes'].keys).to contain_exactly(
        'name', 'code', 'nr_of_rows', 'shared', 'shared_label', 'ishared', 'team',
        'created_at', 'created_by', 'archived_on', 'archived_by', 'urls', 'shared_read',
        'shared_write', 'shareable_write', 'assigned_users', 'default_public_user_role_id',
        'permissions', 'top_level_assignable'
      )
    end
  end

  describe 'POST create' do
    let(:params) { { repository: { name: 'My Repository', repository_template_id: repository_template.id  } } }

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

    it 'returns success response' do
      expect { action }.to change(Repository, :count).by(1)
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(Repository.order(created_at: :desc).first.repository_template).to eq repository_template
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
    let(:params_csv) do
      {
        id: repository.id,
        header_ids: [repository_column.id],
        row_ids: [repository_row.id],
        file_type: :csv
      }
    end

    let(:params_xlsx) do
      {
        id: repository.id,
        header_ids: [repository_column.id],
        row_ids: [repository_row.id],
        file_type: :xlsx
      }
    end

    let(:action_csv) { post :export_repository, params: params_csv, format: :json }
    let(:action_xlsx) { post :export_repository, params: params_xlsx, format: :json }

    it 'calls create activity for exporting inventory items csv' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :export_inventory_items)))

      action_csv
    end

    it 'adds activity in DB for exporting csv' do
      expect { action_csv }
        .to(change { Activity.count })
    end

    it 'calls create activity for exporting inventory items xlsx' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :export_inventory_items)))

      action_xlsx
    end

    it 'adds activity in DB for exporting xlsx' do
      expect { action_xlsx }
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
        .to receive(:import!).and_return({ status: :ok, created_rows_count: 1, updated_rows_count: 1 })

      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :inventory_items_added_or_updated_with_import)))

      action
    end

    it 'adds activity in DB' do
      allow_any_instance_of(ImportRepository::ImportRecords).to receive(:import!)
        .and_return({ status: :ok, created_rows_count: 1, updated_rows_count: 1 })

      expect { action }
        .to(change { Activity.count })
    end
  end
end
