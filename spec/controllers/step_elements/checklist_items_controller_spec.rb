# frozen_string_literal: true

require 'rails_helper'

describe StepElements::ChecklistItemsController, type: :controller do
  login_user

  # Upstream [SCI-13631]: task and protocol-repository contexts with stubbed permission checks.
  describe 'permission checks per context' do
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

  # SCI-13582: effects, activities, ordering and error paths with the real permissions.
  describe 'behaviour with real permissions' do
    include_context 'reference_project_structure', { step: true }

    let(:json) { JSON.parse(response.body) }
    let!(:checklist) { create :checklist, step: step, name: 'Checks' }
    let!(:item_a) { create :checklist_item, checklist: checklist, text: 'First', position: 0 }
    let!(:item_b) { create :checklist_item, checklist: checklist, text: 'Second', position: 1 }
    let(:base_params) { { step_id: step.id, checklist_id: checklist.id } }

    describe 'GET index' do
      it 'returns checklist items' do
        get :index, params: base_params, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['data'].map { |i| i['attributes']['text'] }).to eq %w(First Second)
      end

      it 'returns 404 for unknown step' do
        get :index, params: { step_id: -1, checklist_id: checklist.id }, format: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for checklist outside of the step' do
        other_checklist = create :checklist
        get :index, params: { step_id: step.id, checklist_id: other_checklist.id }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST create' do
      it 'creates an item and logs task activity' do
        expect do
          post :create, params: base_params.merge(attributes: { text: 'Third' }), format: :json
        end.to change { checklist.checklist_items.count }.by(1)
           .and change { Activity.where(type_of: :task_step_checklist_item_added).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(json['data'].map { |i| i['attributes']['text'] }).to eq ['Third']
      end

      it 'splits multiline text into several items after the given item' do
        post :create, params: base_params.merge(attributes: { text: "One\nTwo" }, after_id: item_a.id), format: :json

        expect(response).to have_http_status(:ok)
        expect(checklist.checklist_items.order(:position).pluck(:text)).to eq %w(First One Two Second)
      end

      it 'keeps paragraphs in a single item' do
        post :create, params: base_params.merge(attributes: { text: "One\nTwo", with_paragraphs: true }, after_id: item_a.id),
                      format: :json

        expect(checklist.checklist_items.order(:position).pluck(:text)).to eq ["First", "One\nTwo", 'Second']
        expect(json['data'].first['attributes']['with_paragraphs']).to be true
      end

      it 'creates a paragraph item without after_id' do
        pending 'bug: ChecklistItem#save_multiline! calls nil + 1 when with_paragraphs is set and after_id is missing'
        post :create, params: base_params.merge(attributes: { text: "One\nTwo", with_paragraphs: true }), format: :json

        expect(response).to have_http_status(:ok)
      end

      it 'logs protocol activity for template steps' do
        repo_protocol = create :protocol, :in_repository_draft, team: team, added_by: user
        repo_step = create :step, protocol: repo_protocol
        repo_checklist = create :checklist, step: repo_step

        expect do
          post :create, params: { step_id: repo_step.id, checklist_id: repo_checklist.id, attributes: { text: 'Item' } },
                        format: :json
        end.to change { Activity.where(type_of: :protocol_step_checklist_item_added).count }.by(1)
      end

      it 'returns 422 for blank text' do
        post :create, params: base_params.merge(attributes: { text: ' ', with_paragraphs: true }, after_id: item_a.id),
                      format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to have_key('text')
      end

      it 'returns 403 when the checklist is archived' do
        checklist.update!(archived: true)

        expect do
          post :create, params: base_params.merge(attributes: { text: 'Third' }), format: :json
        end.not_to change(ChecklistItem, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PATCH update' do
      it 'updates the item text and logs an edit activity' do
        expect do
          patch :update, params: base_params.merge(id: item_a.id, attributes: { text: 'Changed' }), format: :json
        end.to change { Activity.where(type_of: :task_step_checklist_item_edited).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(item_a.reload.text).to eq 'Changed'
      end

      it 'adds new items for additional lines' do
        expect do
          patch :update, params: base_params.merge(id: item_a.id, attributes: { text: "Changed\nExtra" }), format: :json
        end.to change { Activity.where(type_of: :task_step_checklist_item_added).count }.by(1)

        expect(checklist.checklist_items.order(:position).pluck(:text)).to eq %w(Changed Extra Second)
      end

      it 'returns 422 for invalid text' do
        patch :update, params: base_params.merge(id: item_a.id, attributes: { text: '', with_paragraphs: true }),
                       format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(item_a.reload.text).to eq 'First'
      end

      it 'returns 404 for unknown item' do
        patch :update, params: base_params.merge(id: -1, attributes: { text: 'x' }), format: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 when user cannot manage the checklist' do
        allow(controller).to receive(:can_manage_step_checklist?).and_return(false)
        patch :update, params: base_params.merge(id: item_a.id, attributes: { text: 'x' }), format: :json

        expect(response).to have_http_status(:forbidden)
        expect(item_a.reload.text).to eq 'First'
      end
    end

    describe 'PATCH toggle' do
      it 'checks an item and logs activity with counts' do
        expect do
          patch :toggle, params: base_params.merge(id: item_a.id, attributes: { checked: true }), format: :json
        end.to change { Activity.where(type_of: :check_step_checklist_item).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(item_a.reload.checked).to be true
        activity = Activity.where(type_of: :check_step_checklist_item).last
        expect(activity.values['message_items']['num_completed']).to eq '1'
        expect(activity.values['message_items']['num_all']).to eq '2'
      end

      it 'unchecks an item and logs activity' do
        item_a.update!(checked: true)

        expect do
          patch :toggle, params: base_params.merge(id: item_a.id, attributes: { checked: false }), format: :json
        end.to change { Activity.where(type_of: :uncheck_step_checklist_item).count }.by(1)

        expect(item_a.reload.checked).to be false
      end

      it 'returns 422 when save fails' do
        allow_any_instance_of(ChecklistItem).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)
        patch :toggle, params: base_params.merge(id: item_a.id, attributes: { checked: true }), format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 403 when user cannot check steps' do
        allow(controller).to receive(:can_check_my_module_steps?).and_return(false)
        patch :toggle, params: base_params.merge(id: item_a.id, attributes: { checked: true }), format: :json

        expect(response).to have_http_status(:forbidden)
        expect(item_a.reload.checked).to be false
      end

      it 'returns 403 when user cannot uncheck steps' do
        item_a.update!(checked: true)
        allow(controller).to receive(:can_uncheck_my_module_steps?).and_return(false)
        patch :toggle, params: base_params.merge(id: item_a.id, attributes: { checked: false }), format: :json

        expect(response).to have_http_status(:forbidden)
        expect(item_a.reload.checked).to be true
      end
    end

    describe 'DELETE destroy' do
      it 'deletes the item and logs activity' do
        expect do
          delete :destroy, params: base_params.merge(id: item_b.id), format: :json
        end.to change(ChecklistItem, :count).by(-1)
           .and change { Activity.where(type_of: :task_step_checklist_item_deleted).count }.by(1)

        expect(response).to have_http_status(:ok)
      end

      it 'returns 422 when destroy fails' do
        allow_any_instance_of(ChecklistItem).to receive(:destroy).and_return(false)
        delete :destroy, params: base_params.merge(id: item_b.id), format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 403 when user cannot manage the checklist' do
        allow(controller).to receive(:can_manage_step_checklist?).and_return(false)

        expect do
          delete :destroy, params: base_params.merge(id: item_b.id), format: :json
        end.not_to change(ChecklistItem, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST reorder' do
      it 'moves the item into the position of the after_id item' do
        item_c = create :checklist_item, checklist: checklist, text: 'Third', position: 2
        post :reorder, params: base_params.merge(id: item_c.id, after_id: item_b.id), format: :json

        expect(response).to have_http_status(:ok)
        expect(checklist.checklist_items.order(:position).pluck(:text)).to eq %w(First Third Second)
      end

      it 'moves the item to the top without after_id' do
        post :reorder, params: base_params.merge(id: item_b.id), format: :json

        expect(checklist.checklist_items.order(:position).pluck(:text)).to eq %w(Second First)
      end

      it 'returns 409 when reordering fails' do
        allow_any_instance_of(ChecklistItem).to receive(:insert_at).and_raise(ActiveRecord::RecordInvalid)
        post :reorder, params: base_params.merge(id: item_b.id), format: :json

        expect(response).to have_http_status(:conflict)
      end
    end
  end
end
