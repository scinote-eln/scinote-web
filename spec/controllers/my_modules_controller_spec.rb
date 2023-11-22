# frozen_string_literal: true

require 'rails_helper'

describe MyModulesController, type: :controller do
  login_user
  include_context 'reference_project_structure'

  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:repository_row) do
    create :repository_row, created_by: user, repository: repository
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }

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
        { id: my_module.id, my_module: { due_date: '2019/03/21 23:59' } }
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
        create :my_module, :with_due_date, experiment: experiment, created_by: experiment.created_by
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
        { id: my_module.id, my_module: { due_date: '2019/02/21 23:59' } }
      end
      let(:my_module) do
        create :my_module, :with_due_date, experiment: experiment, created_by: experiment.created_by
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

  describe 'PUT update_state' do
    let(:action) { put :update_state, params: params, format: :json }
    let(:my_module_id) { my_module.id }
    let(:status_id) { 'some-state-id' }
    let(:params) do
      {
        id: my_module_id,
        my_module: { status_id: status_id }
      }
    end

    before(:all) do
      MyModuleStatusFlow.ensure_default
    end

    context 'when states updated' do
      let(:status_id) { my_module.my_module_status.next_status.id }

      it 'changes status' do
        action

        expect(my_module.reload.my_module_status.id).to be_eql(status_id)
      end

      it 'creates activity' do
        expect { action }.to(change { Activity.all.count }.by(1))
      end
    end

    context 'when status not exist' do
      let(:status_id) { -1 }

      it 'renders 422' do
        my_module.my_module_status_flow
        action

        expect(response).to have_http_status 422
      end
    end

    context 'when status not correct' do
      let(:status_id) { my_module.my_module_status.next_status.next_status.id }

      it 'renders 422' do
        action

        expect(response).to have_http_status 422
      end
    end

    context 'when user does not have permissions' do
      it 'renders 403' do
        UserAssignment.where(user: user, assignable: my_module).destroy_all
        action

        expect(response).to have_http_status 403
      end
    end

    context 'when my_module not found' do
      let(:my_module_id) { -1 }

      it 'renders 404' do
        action

        expect(response).to have_http_status 404
      end
    end
  end

  describe 'POST restore_tasks' do
    let(:action) { post :restore_group, params: params }
    let(:params) do
      {
        id: experiment.id,
        my_modules_ids: [task1.id, task2.id, task3.id]
      }
    end
    let(:task1) { create :my_module, :archived, experiment: experiment, created_by: experiment.created_by }
    let(:task2) { create :my_module, :archived, experiment: experiment, created_by: experiment.created_by }
    let(:task3) { create :my_module, :archived, experiment: experiment, created_by: experiment.created_by }
    let(:user) { controller.current_user }

    context 'when tasks are restored' do
      it 'tasks are active' do
        action

        expect(task1.reload.active?).to be_truthy
        expect(task2.reload.active?).to be_truthy
        expect(task3.reload.active?).to be_truthy
      end

      it 'calls create activity service 3 times' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :restore_module))).exactly(3).times

        action
      end

      it 'adds activity in DB' do
        expect { action }.to(change { Activity.count }.by(3))
      end

      it 'renders 302' do
        action

        expect(response).to have_http_status(302)
      end
    end

    context 'when tasks are not restored' do
      context 'when one task is invalid' do
        before do
          task3.name = Faker::Lorem.characters(number: 300)
          task3.save(validate: false)
        end

        it 'returns 302' do
          action

          expect(response).to have_http_status(302)
        end

        it 'only 2 activities added in DB' do
          expect { action }.to(change { Activity.count }.by(2))
        end

        it 'one task is still archived' do
          action

          expect(task1.reload.active?).to be_truthy
          expect(task2.reload.active?).to be_truthy
          expect(task3.reload.active?).to be_falsey
        end
      end

      context 'when user does not have permissions for one task' do
        before do
          task3.restore!(user)
        end

        it 'returns 302' do
          action

          expect(response).to have_http_status(302)
        end

        it 'only 2 activities added in DB' do
          expect { action }.to(change { Activity.count }.by(2))
        end

        it 'tasks are restored' do
          action

          expect(task1.reload.active?).to be_truthy
          expect(task2.reload.active?).to be_truthy
          expect(task3.reload.active?).to be_truthy
        end
      end
    end
  end
end
