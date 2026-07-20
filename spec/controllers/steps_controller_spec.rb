# frozen_string_literal: true

require 'rails_helper'

describe StepsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    record_deletion_enabled: true,
    step: true
  }

  let(:protocol_repo) do
    create :protocol, :in_repository_draft, team: team, added_by: user
  end
  let(:step_repo) { create :step, protocol: protocol_repo }
  let(:archived_step) { create :step, protocol: my_module.protocol, user: user, archived: true, archived_by: user, archived_on: Time.zone.now }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }

    context 'when in protocol repository' do
      let(:params) do
        { protocol_id: protocol_repo.id,
          step: { name: 'test', description: 'description' }, position: 1 }
      end

      it 'calls create activity for creating step in protocol repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :add_step_to_protocol_repository)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when in protocol on task' do
      let(:params) do
        { protocol_id: my_module.protocol.id,
          step: { name: 'test', description: 'description' }, position: 1 }
      end

      it 'calls create activity for creating step in protocol on task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :create_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }

    context 'when in protocol repository' do
      let(:params) do
        {
          id: step_repo.id,
          protocol_id: protocol_repo.id,
          step: {
            name: 'updated name',
            description: 'updated description'
          }
        }
      end

      it 'calls create activity for editing step in protocol repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :edit_step_in_protocol_repository)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when in protocol on task' do
      let(:params) do
        { id: step.id,
          step: { name: 'updated name', description: 'updated description' } }
      end

      it 'calls create activity for editing step in protocol on task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :edit_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params, format: :json }

    context 'when in protocol repository' do
      let(:params) { { id: step_repo.id } }

      it 'calls create activity for deleting step in protocol repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type:
                                       :delete_step_in_protocol_repository)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when in protocol on task' do
      let(:params) { { id: archived_step.id } }

      it 'calls create activity for deleting step in protocol on task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :destroy_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'POST toggle_step_state' do
    let(:action) { post :toggle_step_state, params: params, format: :json }

    context 'when completing step' do
      let(:step) do
        create :step, protocol: my_module.protocol, user: user, completed: false
      end
      let(:params) { { id: step.id, completed: true } }

      it 'calls create activity for completing step' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :complete_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when uncompleting step' do
      let(:params) { { id: step.id, completed: false } }

      it 'calls create activity for uncompleting step' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :uncomplete_step)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'step locking activities' do
    let!(:step1) { create :step, protocol: protocol_repo }
    let!(:step2) { create :step, protocol: protocol_repo }

    before { allow(Protocol).to receive(:content_locking_enabled?).and_return(true) }

    describe 'POST lock' do
      before { allow(controller).to receive(:can_manage_step?).and_return(true) }

      context 'when other steps remain unlocked' do
        let(:action) { post :lock, params: { id: step1.id }, format: :json }

        it 'logs a step lock activity' do
          expect(Activities::CreateActivityService)
            .to(receive(:call).with(hash_including(activity_type: :lock_protocol_step)))
          action
        end

        it 'does not log an all-steps-locked activity' do
          allow(Activities::CreateActivityService).to receive(:call)
          action
          expect(Activities::CreateActivityService)
            .not_to have_received(:call).with(hash_including(activity_type: :lock_all_protocol_steps))
        end
      end

      context 'when locking the final unlocked step' do
        before { step1.update!(locked: true) }

        let(:action) { post :lock, params: { id: step2.id }, format: :json }

        it 'logs both the step lock and the all-steps-locked activity' do
          allow(Activities::CreateActivityService).to receive(:call)
          action
          expect(Activities::CreateActivityService)
            .to have_received(:call).with(hash_including(activity_type: :lock_protocol_step)).once
          expect(Activities::CreateActivityService)
            .to have_received(:call).with(hash_including(activity_type: :lock_all_protocol_steps)).once
        end
      end

      context 'when the step is already locked' do
        before { step1.update!(locked: true) }

        let(:action) { post :lock, params: { id: step1.id }, format: :json }

        it 'does not log an activity' do
          allow(Activities::CreateActivityService).to receive(:call)
          action
          expect(Activities::CreateActivityService).not_to have_received(:call)
        end
      end
    end

    describe 'POST unlock' do
      before do
        allow(controller).to receive(:can_manage_step?).and_return(true)
        step1.update!(locked: true)
        step2.update!(locked: true)
      end

      let(:action) { post :unlock, params: { id: step1.id }, format: :json }

      it 'logs a step unlock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :unlock_protocol_step)))
        action
      end

      it 'never logs an all-steps-unlocked activity on the individual path' do
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService)
          .not_to have_received(:call).with(hash_including(activity_type: :unlock_all_protocol_steps))
      end
    end

    describe 'POST lock_all' do
      before { allow(controller).to receive(:can_manage_protocol_draft_in_repository?).and_return(true) }

      let(:action) { post :lock_all, params: { protocol_id: protocol_repo.id }, format: :json }

      it 'logs a lock activity for each step plus the all-steps summary' do
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService)
          .to have_received(:call).with(hash_including(activity_type: :lock_protocol_step)).twice
        expect(Activities::CreateActivityService)
          .to have_received(:call).with(hash_including(activity_type: :lock_all_protocol_steps)).once
      end

      it 'only logs step lock activities for steps that were unlocked' do
        step1.update!(locked: true)
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService)
          .to have_received(:call).with(hash_including(activity_type: :lock_protocol_step)).once
        expect(Activities::CreateActivityService)
          .to have_received(:call).with(hash_including(activity_type: :lock_all_protocol_steps)).once
      end
    end

    describe 'POST unlock_all' do
      before do
        allow(controller).to receive(:can_manage_protocol_draft_in_repository?).and_return(true)
        step1.update!(locked: true)
        step2.update!(locked: true)
      end

      let(:action) { post :unlock_all, params: { protocol_id: protocol_repo.id }, format: :json }

      it 'logs an unlock activity for each step plus the all-steps summary' do
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService)
          .to have_received(:call).with(hash_including(activity_type: :unlock_protocol_step)).twice
        expect(Activities::CreateActivityService)
          .to have_received(:call).with(hash_including(activity_type: :unlock_all_protocol_steps)).once
      end
    end
  end
end
