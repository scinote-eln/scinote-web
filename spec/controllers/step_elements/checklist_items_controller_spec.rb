# frozen_string_literal: true

require 'rails_helper'

describe StepElements::ChecklistItemsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {}

  let(:protocol_repo) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:step_repo) { create :step, protocol: protocol_repo }
  let(:step_task) { create :step, protocol: my_module.protocol }

  let(:checklist) { create :checklist, step: current_step }
  let!(:checklist_item) { create :checklist_item, checklist: checklist, text: 'Item 1' }
  let(:base_params) { { step_id: current_step.id, checklist_id: checklist.id } }

  before do
    allow(Activities::CreateActivityService).to receive(:call)
    allow(controller).to receive(:checklist_item_annotation)
  end

  shared_examples 'checklist item actions' do |prefix|
    describe 'GET index' do
      let(:action) { get :index, params: base_params, format: :json }

      it 'returns checklist items' do
        allow(controller).to receive(:can_read_protocol_in_module?).and_return(prefix == 'task')
        allow(controller).to receive(:can_read_protocol_in_repository?).and_return(prefix == 'protocol')
        action
        expect(response).to have_http_status(:ok)
      end

      it 'returns forbidden without permissions' do
        allow(controller).to receive(:can_read_protocol_in_module?).and_return(false)
        allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST create' do
      let(:action) do
        post :create, params: base_params.merge(attributes: { text: 'New item' }), format: :json
      end

      context 'when user has permissions' do
        before { allow(controller).to receive(:can_manage_step_checklist?).and_return(true) }

        it 'creates checklist item and logs activity' do
          expect { action }.to change(ChecklistItem, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(Activities::CreateActivityService)
            .to have_received(:call).with(hash_including(activity_type: "#{prefix}_step_checklist_item_added"))
        end

        it 'returns unprocessable entity when record is invalid' do
          allow_any_instance_of(ChecklistItem)
            .to receive(:save_multiline!).and_raise(ActiveRecord::RecordInvalid.new(ChecklistItem.new))
          action
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      it 'returns forbidden without permissions' do
        allow(controller).to receive(:can_manage_step_checklist?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PATCH update' do
      let(:text) { 'Updated' }
      let(:action) do
        patch :update,
              params: base_params.merge(id: checklist_item.id, attributes: { text: text }),
              format: :json
      end

      context 'when user has permissions' do
        before { allow(controller).to receive(:can_manage_step_checklist?).and_return(true) }

        it 'updates checklist item and logs activity' do
          action
          expect(response).to have_http_status(:ok)
          expect(checklist_item.reload.text).to eq 'Updated'
          expect(Activities::CreateActivityService)
            .to have_received(:call).with(hash_including(activity_type: "#{prefix}_step_checklist_item_edited"))
        end

        context 'with multiline text' do
          let(:text) { "Line 1\nLine 2" }

          it 'logs added activity for extra lines' do
            action
            expect(Activities::CreateActivityService)
              .to have_received(:call).with(hash_including(activity_type: "#{prefix}_step_checklist_item_added"))
          end
        end

        it 'returns unprocessable entity when record is invalid' do
          allow_any_instance_of(ChecklistItem)
            .to receive(:save_multiline!).and_raise(ActiveRecord::RecordInvalid.new(ChecklistItem.new))
          action
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      it 'returns forbidden without permissions' do
        allow(controller).to receive(:can_manage_step_checklist?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PATCH toggle' do
      context 'when checking an item' do
        let(:action) do
          patch :toggle,
                params: base_params.merge(id: checklist_item.id, attributes: { checked: true }),
                format: :json
        end

        context 'when user has permissions' do
          before { allow(controller).to receive(:can_check_my_module_steps?).and_return(true) }

          it 'checks the item and logs activity' do
            action
            expect(response).to have_http_status(:ok)
            expect(checklist_item.reload.checked).to be true
            expect(Activities::CreateActivityService)
              .to have_received(:call).with(hash_including(activity_type: :check_step_checklist_item))
          end

          it 'returns unprocessable entity when record is invalid' do
            allow_any_instance_of(ChecklistItem)
              .to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(ChecklistItem.new))
            action
            expect(response).to have_http_status(:unprocessable_content)
          end
        end

        it 'returns forbidden without permissions' do
          allow(controller).to receive(:can_check_my_module_steps?).and_return(false)
          action
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when unchecking an item' do
        before { checklist_item.update!(checked: true) }

        let(:action) do
          patch :toggle,
                params: base_params.merge(id: checklist_item.id, attributes: { checked: false }),
                format: :json
        end

        it 'unchecks the item and logs activity' do
          allow(controller).to receive(:can_uncheck_my_module_steps?).and_return(true)
          action
          expect(response).to have_http_status(:ok)
          expect(checklist_item.reload.checked).to be false
          expect(Activities::CreateActivityService)
            .to have_received(:call).with(hash_including(activity_type: :uncheck_step_checklist_item))
        end

        it 'returns forbidden without permissions' do
          allow(controller).to receive(:can_uncheck_my_module_steps?).and_return(false)
          action
          expect(response).to have_http_status(:forbidden)
        end
      end
    end

    describe 'DELETE destroy' do
      let(:action) { delete :destroy, params: base_params.merge(id: checklist_item.id), format: :json }

      context 'when user has permissions' do
        before { allow(controller).to receive(:can_manage_step_checklist?).and_return(true) }

        it 'destroys checklist item and logs activity' do
          expect { action }.to change(ChecklistItem, :count).by(-1)
          expect(response).to have_http_status(:ok)
          expect(Activities::CreateActivityService)
            .to have_received(:call).with(hash_including(activity_type: "#{prefix}_step_checklist_item_deleted"))
        end

        it 'returns unprocessable entity when destroy fails' do
          allow_any_instance_of(ChecklistItem).to receive(:destroy).and_return(false)
          action
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      it 'returns forbidden without permissions' do
        allow(controller).to receive(:can_manage_step_checklist?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST reorder' do
      let!(:second_item) { create :checklist_item, checklist: checklist, text: 'Item 2' }
      let(:action) do
        post :reorder,
             params: base_params.merge(id: checklist_item.id, after_id: second_item.id),
             format: :json
      end

      it 'reorders checklist items' do
        allow(controller).to receive(:can_manage_step_checklist?).and_return(true)
        action
        expect(response).to have_http_status(:ok)
      end

      it 'returns forbidden without permissions' do
        allow(controller).to receive(:can_manage_step_checklist?).and_return(false)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'when in protocol repository' do
    let(:current_step) { step_repo }

    it_behaves_like 'checklist item actions', 'protocol'
  end

  context 'when in protocol on task' do
    let(:current_step) { step_task }

    it_behaves_like 'checklist item actions', 'task'
  end

  describe 'not found' do
    let(:current_step) { step_repo }

    before { allow(controller).to receive(:can_manage_step_checklist?).and_return(true) }

    it 'returns not found for missing step' do
      delete :destroy, params: { step_id: -1, checklist_id: checklist.id, id: checklist_item.id }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for missing checklist' do
      delete :destroy, params: { step_id: current_step.id, checklist_id: -1, id: checklist_item.id }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for missing checklist item' do
      delete :destroy, params: base_params.merge(id: -1), format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
