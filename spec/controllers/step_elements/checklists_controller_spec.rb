# frozen_string_literal: true

require 'rails_helper'

describe StepElements::ChecklistsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:step) { create :step, protocol: protocol }
  let!(:checklist) { create :checklist, step: step }

  describe 'POST lock' do
    let(:action) { post :lock, params: { step_id: step.id, id: checklist.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_lock_step_checklist?).and_return(true) }

      it 'locks the checklist' do
        action
        expect(response).to have_http_status(:ok)
        expect(checklist.reload.locked).to be true
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_lock_step_checklist?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST unlock' do
    before { checklist.update!(locked: true) }

    let(:action) { post :unlock, params: { step_id: step.id, id: checklist.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_unlock_step_checklist?).and_return(true) }

      it 'unlocks the checklist' do
        action
        expect(response).to have_http_status(:ok)
        expect(checklist.reload.locked).to be false
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_unlock_step_checklist?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
