# frozen_string_literal: true

require 'rails_helper'

describe MyModulesController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, :admin, user: user, team: team }
  let(:project) { create :project, team: team, created_by: user }
  let!(:user_project) do
    create :user_project, :normal_user, user: user, project: project
  end
  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:repository_row) do
    create :repository_row, created_by: user, repository: repository
  end
  let(:experiment) { create :experiment, project: project }
  let(:my_module) { create :my_module, experiment: experiment }

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }

    context 'when restoring task from archive' do
      let(:params) { { id: my_module.id, my_module: { archived: false } } }
      let(:my_module) do
        create :my_module, archived: true, experiment: experiment
      end

      it 'calls create activity for restoring task from archive' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :restore_module)))

        put :update, params: params
      end

      it 'adds activity in DB' do
        expect { put :update, params: params }
          .to(change { Activity.count })
      end
    end

    context 'when changing task description' do
      let(:params) do
        { id: my_module.id, my_module: { description: 'description changed' } }
      end

      it 'calls create activity for changing task description' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :change_module_description)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when setting due_date' do
      let(:params) do
        { id: my_module.id, my_module: { due_date: '03/21/2019' } }
      end

      it 'calls create activity for setting due date' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :set_task_due_date)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when deleting due_date' do
      let(:params) { { id: my_module.id, my_module: { due_date: '' } } }
      let(:my_module) do
        create :my_module, :with_due_date, experiment: experiment
      end

      it 'calls create activity for removing due date' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :remove_task_due_date)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when updating due_date' do
      let(:params) do
        { id: my_module.id, my_module: { due_date: '02/21/2019' } }
      end
      let(:my_module) do
        create :my_module, :with_due_date, experiment: experiment
      end

      it 'calls create activity for changing due date' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :change_task_due_date)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'POST assign_repository_records' do
    let(:params) do
      { id: my_module.id,
        repository_id: repository.id,
        selected_rows: [repository_row.id],
        downstream: false }
    end
    let(:action) do
      post :assign_repository_records, params: params, format: :json
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

  describe 'POST assign_repository_records_downstream' do
    it 'adds activity id DB' do
      parent_my_module = my_module
      params_downstream = { id: parent_my_module.id,
                            repository_id: repository.id,
                            selected_rows: [repository_row.id],
                            downstream: true }
      3.times do |_i|
        child_module = create :my_module, experiment: experiment
        Connection.create(output_id: parent_my_module.id, input_id: child_module.id)
      end
      expect { post :assign_repository_records, params: params_downstream, format: :json }
        .to change { Activity.count }.by(4)
    end
  end

  describe 'POST unassign_repository_records' do
    let!(:mm_repository_row) do
      create :mm_repository_row, repository_row: repository_row,
                                 my_module: my_module,
                                 assigned_by: user
    end
    let(:params) do
      { id: my_module.id,
        repository_id: repository.id,
        selected_rows: [repository_row.id],
        downstream: false }
    end
    let(:action) do
      post :unassign_repository_records, params: params, format: :json
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

  describe 'POST unassign_repository_records_downstream' do
    it 'adds activity id DB' do
      parent_my_module = my_module
      create :mm_repository_row, repository_row: repository_row,
                                 my_module: parent_my_module,
                                 assigned_by: user
      params_downstream = { id: parent_my_module.id,
                            repository_id: repository.id,
                            selected_rows: [repository_row.id],
                            downstream: true }
      3.times do |_i|
        child_module = create :my_module, experiment: experiment
        Connection.create(output_id: parent_my_module.id, input_id: child_module.id)
        create :mm_repository_row, repository_row: repository_row,
                                 my_module: child_module,
                                 assigned_by: user
      end
      post :unassign_repository_records, params: params_downstream, format: :json
      expect(Activity.count).to eq 4
    end
  end

  describe 'POST toggle_task_state' do
    let(:action) { post :toggle_task_state, params: params, format: :json }
    let(:params) { { id: my_module.id } }

    context 'when completing task' do
      let(:my_module) do
        create :my_module, state: 'uncompleted', experiment: experiment
      end

      it 'calls create activity for completing task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :complete_task)))
        action
      end
    end

    context 'when uncompleting task' do
      let(:my_module) do
        create :my_module, state: 'completed', experiment: experiment
      end

      it 'calls create activity for uncompleting task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :uncomplete_task)))
        action
      end
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
