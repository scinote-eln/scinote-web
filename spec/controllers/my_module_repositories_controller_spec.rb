# frozen_string_literal: true

require 'rails_helper'

describe MyModuleRepositoriesController, type: :controller do
  login_user
  include_context 'reference_project_structure'
  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:repository_row) do
    create :repository_row, created_by: user, repository: repository
  end
  let!(:repository_row_2) do
    create :repository_row, created_by: user, repository: repository
  end

  describe 'PUT update (assign repository records)' do
    let(:params) do
      { my_module_id: my_module.id,
        id: repository.id,
        rows_to_assign: [repository_row.id],
        downstream: false }
    end
    let(:action) do
      put :update, params: params, format: :json
    end

    it 'calls create activity for assign_repository_record' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :assign_repository_record)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update (assign repository records downstream)' do
    it 'adds activity id DB' do
      parent_my_module = my_module
      params_downstream = { my_module_id: parent_my_module.id,
                            id: repository.id,
                            rows_to_assign: [repository_row.id],
                            downstream: true }
      3.times do |_i|
        child_module = create :my_module, experiment: experiment, created_by: experiment.created_by
        Connection.create(output_id: parent_my_module.id, input_id: child_module.id)
      end
      expect { put :update, params: params_downstream, format: :json }
        .to change { Activity.count }.by(4)
    end
  end

  describe 'PUT update (unassign repository records)' do
    let!(:mm_repository_row) do
      create :mm_repository_row, repository_row: repository_row,
                                 my_module: my_module,
                                 assigned_by: user
    end
    let(:params) do
      { my_module_id: my_module.id,
        id: repository.id,
        rows_to_unassign: [repository_row.id],
        downstream: false }
    end
    let(:action) do
      put :update, params: params, format: :json
    end

    it 'calls create activity for unassign_repository_record' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :unassign_repository_record)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update (unassign repository records downstream)' do
    it 'adds activity id DB' do
      parent_my_module = my_module
      create :mm_repository_row, repository_row: repository_row,
                                 my_module: parent_my_module,
                                 assigned_by: user
      params_downstream = { my_module_id: parent_my_module.id,
                            id: repository.id,
                            rows_to_unassign: [repository_row.id],
                            downstream: true }
      3.times do |_i|
        child_module = create :my_module, experiment: experiment, created_by: experiment.created_by
        Connection.create(output_id: parent_my_module.id, input_id: child_module.id)
        create :mm_repository_row, repository_row: repository_row,
                                   my_module: child_module,
                                   assigned_by: user
      end
      put :update, params: params_downstream, format: :json
      expect(Activity.count).to eq 4
    end
  end

  describe 'PUT update (assign and unassign repository records)' do
    let!(:mm_repository_row) do
      create :mm_repository_row, repository_row: repository_row_2,
                                 my_module: my_module,
                                 assigned_by: user
    end
    let(:params) do
      { my_module_id: my_module.id,
        id: repository.id,
        rows_to_assign: [repository_row.id],
        rows_to_unassign: [repository_row_2.id],
        downstream: false }
    end
    let(:action) do
      put :update, params: params, format: :json
    end

    it 'calls create activity for assign_repository_record and unassign_repository_record' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :assign_repository_record)))
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type:
                                     :unassign_repository_record)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update (assign and unassign repository records downstream)' do
    it 'adds activity id DB' do
      parent_my_module = my_module
      create :mm_repository_row, repository_row: repository_row_2,
                                 my_module: parent_my_module,
                                 assigned_by: user
      params_downstream = { my_module_id: parent_my_module.id,
                            id: repository.id,
                            rows_to_assign: [repository_row.id],
                            rows_to_unassign: [repository_row_2.id],
                            downstream: true }
      3.times do |_i|
        child_module = create :my_module, experiment: experiment, created_by: experiment.created_by
        Connection.create(output_id: parent_my_module.id, input_id: child_module.id)
        create :mm_repository_row, repository_row: repository_row_2,
                                   my_module: child_module,
                                   assigned_by: user
      end
      put :update, params: params_downstream, format: :json
      expect(Activity.count).to eq 8
    end
  end
end
