# frozen_string_literal: true

require 'rails_helper'

describe StepElements::TextsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:step) { create :step, protocol: protocol }
  let!(:step_text) { create :step_text, step: step }

  describe 'POST lock' do
    let(:action) { post :lock, params: { step_id: step.id, id: step_text.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_lock_step_text?).and_return(true) }

      it 'locks the step text' do
        action
        expect(response).to have_http_status(:ok)
        expect(step_text.reload.locked).to be true
      end

      it 'logs a lock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'lock_protocol_step_text')))
        action
      end

      it 'does not log an activity when the text is already locked' do
        step_text.update!(locked: true)
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService).not_to have_received(:call)
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_lock_step_text?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST unlock' do
    before { step_text.update!(locked: true) }

    let(:action) { post :unlock, params: { step_id: step.id, id: step_text.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_unlock_step_text?).and_return(true) }

      it 'unlocks the step text' do
        action
        expect(response).to have_http_status(:ok)
        expect(step_text.reload.locked).to be false
      end

      it 'logs an unlock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'unlock_protocol_step_text')))
        action
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_unlock_step_text?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
