# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user, users: [user] }
  let!(:project) { create :project, team: team }
  let!(:user_project) do
    create :user_project, :owner, user: user, project: project
  end
  let(:experiment) { create :experiment, project: project }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { project_id: project.id,
        experiment: { name: 'test experiment A1',
                      description: 'test description one' } }
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :create_experiment))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params }

    context 'when editing experiment' do
      let(:params) do
        {
          id: experiment.id,
          experiment: { title: 'new_title' }
        }
      end

      it 'calls create activity for editing experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :edit_experiment)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when archiving experiment' do
      let(:archived_experiment) do
        create :experiment,
               archived: true,
               archived_by: (create :user),
               archived_on: Time.zone.now,
               project: project
      end

      let(:params) do
        {
          id: archived_experiment.id,
          experiment: { archived: false }
        }
      end

      it 'calls create activity for unarchiving experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
            .with(hash_including(activity_type: :restore_experiment)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'GET archive' do
    let(:action) { get :archive, params: params, format: :json }
    let(:params) do
      { id: experiment.id,
        experiment: { archived: false } }
    end
    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :archive_experiment))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PATCH restore_tasks' do
    let(:action) { patch :restore_tasks, params: params, format: :json }
    let(:params) do
      {
        id: experiment.id,
        restore_task_ids: [task1.id, task2.id, task3.id]
      }
    end
    let(:experiment) { create :experiment }
    let(:task1) { create :my_module, :archived, experiment: experiment }
    let(:task2) { create :my_module, :archived, experiment: experiment }
    let(:task3) { create :my_module, :archived, experiment: experiment }
    let(:user) { controller.current_user }
    let!(:user_project) { create :user_project, user: user, project: experiment.project, role: 0 }

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

      it 'renders 200' do
        action

        expect(response).to have_http_status(200)
      end
    end

    context 'when tasks are not restored' do
      context 'when ona task is invalid' do
        before do
          task3.name = Faker::Lorem.characters(number: 300)
          task3.save(validate: false)
        end

        it 'returns 422, have errors' do
          action

          expect(JSON.parse(response.body)).to have_key('errors')
          expect(response).to have_http_status(422)
        end

        it 'does not add activities in DB' do
          expect { action }.not_to(change { Activity.count })
        end

        it 'tasks are still archived' do
          action

          expect(task1.active?).to be_falsey
          expect(task2.active?).to be_falsey
          expect(task3.active?).to be_falsey
        end
      end

      context 'when user does not have permissions for one task' do
        before do
          task3.restore!(user)
        end

        it 'returns 403' do
          action

          expect(response).to have_http_status(403)
        end

        it 'does not add activities in DB' do
          expect { action }.not_to(change { Activity.count })
        end

        it 'tasks are still archived' do
          action

          expect(task1.active?).to be_falsey
          expect(task2.active?).to be_falsey
          expect(task3.active?).to be_truthy
        end
      end
    end
  end
end
