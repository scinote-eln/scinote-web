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
        { id: my_module.id, my_module: { due_date: '03/21/2019 23:59' } }
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
        { id: my_module.id, my_module: { due_date: '02/21/2019 23:59' } }
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
    let(:my_module_status_flow) { create :my_module_status_flow, :in_team, team: team}
    let(:status1) {create :my_module_status, my_module_status_flow: my_module_status_flow}
    let(:status2) {create :my_module_status, my_module_status_flow: my_module_status_flow}

    context 'when states updated' do
      let(:status_id) { status2.id }

      before do
        my_module.update(my_module_status: status1)
      end

      it 'changes status' do
        action

        expect(my_module.reload.my_module_status.name).to be_eql(status2.name)
        expect(response).to have_http_status 200
      end
    end

    context 'when status not found' do
      let(:status_id) { -1 }

      before do
        my_module.update(my_module_status: status1)
      end

      it 'renders 404' do
        action

        expect(response).to have_http_status 404
      end
    end

    context 'when my_module does not have assign flow yet' do
      let(:status_id) { -1 }

      it 'renders 404' do
        action

        expect(response).to have_http_status 404
      end
    end

    context 'when user does not have permissions' do
      it 'renders 403' do
        # Remove user from project
        UserProject.where(user: user, project: project).destroy_all
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
end
