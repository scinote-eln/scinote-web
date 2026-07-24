# frozen_string_literal: true

require 'rails_helper'

describe StepElements::TablesController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:step) { create :step, protocol: protocol }
  let!(:step_table) { create :step_table, step: step }
  let!(:table) { step_table.table }

  describe 'POST lock' do
    let(:action) { post :lock, params: { step_id: step.id, id: table.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_lock_step_table?).and_return(true) }

      it 'locks the table' do
        action
        expect(response).to have_http_status(:ok)
        expect(table.reload.locked).to be true
      end

      it 'logs a lock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'lock_protocol_step_table')))
        action
      end

      it 'does not log an activity when the table is already locked' do
        table.update!(locked: true)
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService).not_to have_received(:call)
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_lock_step_table?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST unlock' do
    before { table.update!(locked: true) }

    let(:action) { post :unlock, params: { step_id: step.id, id: table.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_unlock_step_table?).and_return(true) }

      it 'unlocks the table' do
        action
        expect(response).to have_http_status(:ok)
        expect(table.reload.locked).to be false
      end

      it 'logs an unlock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: 'unlock_protocol_step_table')))
        action
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_unlock_step_table?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
