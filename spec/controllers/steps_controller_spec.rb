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
  let(:step_task) { create :step, protocol: my_module.protocol }
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

    context 'when locking the attachments section in protocol repository' do
      let(:params) do
        { id: step_repo.id, protocol_id: protocol_repo.id, step: { attachments_locked: true } }
      end

      it 'calls create activity for locking step files' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :lock_protocol_step_files)))
        action
      end
    end

    context 'when unlocking the attachments section in protocol repository' do
      let(:step_repo) { create :step, protocol: protocol_repo, attachments_locked: true }
      let(:params) do
        { id: step_repo.id, protocol_id: protocol_repo.id, step: { attachments_locked: false } }
      end

      it 'calls create activity for unlocking step files' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :unlock_protocol_step_files)))
        action
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

  describe 'POST duplicate' do
    let(:action) { post :duplicate, params: params, format: :json }

    context 'when in protocol repository' do
      let(:params) do
        { id: step_repo.id }
      end

      it 'calls create activity for creating step in protocol repository' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :protocol_step_duplicated)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when in protocol repository and user does not have permissions' do
      let(:params) do
        { id: step_repo.id }
      end

      it 'renders 403' do
        UserAssignment.where(user: user, assignable: protocol_repo).destroy_all
        action

        expect(response).to have_http_status 403
      end
    end

    context 'when in protocol on task' do
      let(:params) do
        { id: step_task.id }
      end

      it 'calls create activity for creating step in protocol on task' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :task_step_duplicated)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when in protocol on task and user does not have permissions' do
      let(:params) do
        { id: step_task.id }
      end

      it 'renders 403' do
        UserAssignment.where(user: user, assignable: my_module).destroy_all
        action

        expect(response).to have_http_status 403
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

  describe 'additional actions' do
    let(:json) { JSON.parse(response.body) }
    let(:task_protocol) { my_module.protocol }

    describe 'GET index' do
      let!(:active_step) { create :step, protocol: task_protocol, user: user, position: 0, name: 'Alpha' }
      let!(:archived_task_step) do
        create :step, protocol: task_protocol, user: user, position: nil, name: 'Zeta',
                      archived: true, archived_by: user, archived_on: Time.zone.now
      end

      it 'returns active steps ordered by position' do
        get :index, params: { protocol_id: task_protocol.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['data'].map { |s| s['id'].to_i }).to eq [active_step.id]
      end

      it 'returns archived steps and stores the sort preference' do
        get :index, params: { protocol_id: task_protocol.id, view_mode: 'archived', sort: 'name_desc' }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['data'].map { |s| s['id'].to_i }).to eq [archived_task_step.id]
        expect(json['meta']['sort']).to eq 'name_desc'
        setting = user.user_settings.find_by(key: 'protocol_steps_order_archived')
        expect(setting.value[my_module.id.to_s]).to eq 'name_desc'
      end

      %w(updated_at_asc updated_at_desc created_at_asc created_at_desc name_asc).each do |sort|
        it "applies the #{sort} sort for archived steps" do
          get :index, params: { protocol_id: task_protocol.id, view_mode: 'archived', sort: sort }, format: :json

          expect(json['meta']['sort']).to eq sort
          expect(json['data'].size).to eq 1
        end
      end

      it 'uses the stored sort preference when no sort param is given' do
        get :index, params: { protocol_id: task_protocol.id, view_mode: 'archived' }, format: :json

        expect(json['meta']['sort']).to eq 'created_at_desc'
      end

      it 'applies date filters to archived steps' do
        get :index, params: { protocol_id: task_protocol.id, view_mode: 'archived',
                              created_at_from: 1.day.from_now.iso8601, created_at_to: 2.days.from_now.iso8601,
                              updated_at_from: 1.day.ago.iso8601, updated_at_to: 2.days.from_now.iso8601 },
                    format: :json

        expect(json['data']).to be_empty
      end

      it 'applies text query filter to archived steps' do
        get :index, params: { protocol_id: task_protocol.id, view_mode: 'archived', query: 'Zeta' }, format: :json

        expect(json['data'].map { |s| s['id'].to_i }).to eq [archived_task_step.id]
      end

      it 'returns 404 for unknown protocol' do
        get :index, params: { protocol_id: -1 }, format: :json

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 403 when user cannot read the protocol' do
        allow(controller).to receive(:can_read_protocol_in_module?).and_return(false)
        allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
        get :index, params: { protocol_id: task_protocol.id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET list' do
      render_views

      it 'returns step labels' do
        s = create :step, protocol: task_protocol, user: user, position: 0, name: 'Listed'
        get :list, params: { protocol_id: task_protocol.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json).to eq [[s.id, s.label]]
      end
    end

    describe 'GET show' do
      render_views

      it 'renders the step partial' do
        pending 'bug: steps/_comments partial calls undefined step_step_comments_path, so GET /steps/:id raises 500'
        get :show, params: { id: step.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['html']).to include(step.name)
      end

      it 'returns 404 for unknown step' do
        get :show, params: { id: -1 }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET elements' do
      let!(:step_text) { create :step_text, step: step, text: 'Some text' }
      let!(:text_element) { create :step_orderable_element, step: step, orderable: step_text, position: 0 }
      let!(:checklist) { create :checklist, step: step }
      let!(:checklist_element) { create :step_orderable_element, step: step, orderable: checklist, position: 1 }
      let!(:step_table) { create :step_table, step: step, table: create(:table, team: team) }
      let!(:table_element) { create :step_orderable_element, step: step, orderable: step_table, position: 2 }

      it 'returns serialized active elements ordered by position' do
        get :elements, params: { id: step.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['data'].map { |e| e['type'] }).to eq %w(StepText Checklist Table)
      end

      it 'returns archived elements in archived view mode' do
        checklist.update!(archived: true)
        get :elements, params: { id: step.id, view_mode: 'archived' }, format: :json

        expect(json['data'].map { |e| e['id'].to_i }).to eq [checklist.id]
      end

      it 'returns 403 when user cannot read the protocol' do
        allow(controller).to receive(:can_read_protocol_in_module?).and_return(false)
        allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
        get :elements, params: { id: step.id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET attachments' do
      let!(:active_asset) { create :step_asset, step: step }
      let!(:archived_asset) do
        create(:step_asset, step: step).tap { |sa| sa.asset.update!(archived: true) }
      end

      it 'returns active assets' do
        get :attachments, params: { id: step.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['data'].map { |a| a['id'].to_i }).to eq [active_asset.asset.id]
      end

      it 'returns archived assets in archived view mode' do
        get :attachments, params: { id: step.id, view_mode: 'archived' }, format: :json

        expect(json['data'].map { |a| a['id'].to_i }).to eq [archived_asset.asset.id]
      end
    end

    describe 'POST upload_attachment' do
      let(:blob) do
        ActiveStorage::Blob.create_and_upload!(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')),
                                               filename: 'test.jpg', content_type: 'image/jpeg')
      end

      it 'creates an asset on a task step and logs activity' do
        expect do
          post :upload_attachment, params: { id: step.id, signed_blob_id: blob.signed_id }, format: :json
        end.to change { step.assets.count }.by(1)
           .and change { Activity.where(type_of: :task_step_file_added).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(step.assets.last.file_name).to eq 'test.jpg'
      end

      it 'logs protocol activity for template step' do
        allow(controller).to receive(:can_manage_step_attachments?).and_return(true)
        expect do
          post :upload_attachment, params: { id: step_repo.id, signed_blob_id: blob.signed_id }, format: :json
        end.to change { Activity.where(type_of: :protocol_step_file_added).count }.by(1)
      end

      it 'returns 403 when attachments are locked' do
        step.update_column(:attachments_locked, true)
        post :upload_attachment, params: { id: step.id, signed_blob_id: blob.signed_id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST create edge cases' do
      it 'creates locked step in template draft when all other steps are locked' do
        create :step, protocol: protocol_repo, locked: true, position: 0
        post :create, params: { protocol_id: protocol_repo.id, position: 1 }, format: :json

        expect(response).to have_http_status(:ok)
        expect(protocol_repo.steps.find_by(position: 1).locked).to be true
      end

      it 'returns 422 when protocol has errors' do
        allow_any_instance_of(Protocol).to receive(:insert_step) do |protocol, new_step, _position|
          protocol.errors.add(:base, 'boom')
          new_step
        end
        post :create, params: { protocol_id: protocol_repo.id, position: 0 }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to be_present
      end

      it 'returns 403 when user cannot create steps on task' do
        allow(controller).to receive(:can_create_my_module_steps?).and_return(false)
        expect do
          post :create, params: { protocol_id: task_protocol.id, position: 0 }, format: :json
        end.not_to change(Step, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PUT update failure' do
      it 'returns 422 for invalid name' do
        put :update, params: { id: step.id, step: { name: 'a' * 300 } }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(step.reload.name).not_to eq 'a' * 300
      end

      it 'returns 403 when step is locked' do
        step.update_column(:locked, true)
        put :update, params: { id: step.id, step: { name: 'new' } }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST duplicate' do
      it 'shifts positions of following steps and names the copy' do
        first = create :step, protocol: protocol_repo, position: 0, name: 'First'
        second = create :step, protocol: protocol_repo, position: 1, name: 'Second'
        post :duplicate, params: { id: first.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(second.reload.position).to eq 2
        expect(protocol_repo.steps.find_by(position: 1).name).to eq 'First (1)'
      end

      it 'returns 422 when duplication fails' do
        allow_any_instance_of(Step).to receive(:duplicate).and_raise(ActiveRecord::RecordInvalid)
        post :duplicate, params: { id: step_repo.id }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'POST archive' do
      it 'archives step, shifts positions and logs activity' do
        first = create :step, protocol: task_protocol, user: user, position: 0
        second = create :step, protocol: task_protocol, user: user, position: 1

        expect do
          post :archive, params: { id: first.id }, format: :json
        end.to change { Activity.where(type_of: :archive_step).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(first.reload.archived).to be true
        expect(first.position).to be_nil
        expect(second.reload.position).to eq 0
      end

      it 'returns 403 for template step' do
        post :archive, params: { id: step_repo.id }, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(step_repo.reload.archived).to be false
      end
    end

    describe 'POST restore' do
      it 'restores step at the end and returns empty json' do
        create :step, protocol: task_protocol, user: user, position: 4
        archived = create :step, protocol: task_protocol, user: user, position: nil,
                                 archived: true, archived_by: user, archived_on: Time.zone.now

        expect do
          post :restore, params: { id: archived.id }, format: :json
        end.to change { Activity.where(type_of: :restore_step).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(json).to eq({})
        expect(archived.reload.archived).to be false
        expect(archived.position).to eq 5
      end

      it 'returns serialized step when it still has archived elements' do
        archived = create :step, protocol: task_protocol, user: user, position: nil,
                                 archived: true, archived_by: user, archived_on: Time.zone.now
        create :checklist, step: archived, archived: true
        post :restore, params: { id: archived.id }, format: :json

        expect(json['data']['id'].to_i).to eq archived.id
        expect(archived.reload.position).to eq 0
      end

      it 'returns 403 for active step' do
        post :restore, params: { id: step.id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST lock/unlock without locking enabled' do
      it 'returns 403 for lock' do
        allow(Protocol).to receive(:content_locking_enabled?).and_return(false)
        post :lock, params: { id: step_repo.id }, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(step_repo.reload.locked).to be false
      end

      it 'returns 403 for lock_all' do
        allow(Protocol).to receive(:content_locking_enabled?).and_return(false)
        post :lock_all, params: { protocol_id: protocol_repo.id }, format: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 422 when lock fails validation' do
        allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
        allow_any_instance_of(Step).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        post :lock, params: { id: step_repo.id }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 422 when unlock fails validation' do
        allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
        allow_any_instance_of(Step).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        post :unlock, params: { id: step_repo.id }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 422 when lock_all/unlock_all fail validation' do
        step_repo
        allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
        allow_any_instance_of(Step).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        post :lock_all, params: { protocol_id: protocol_repo.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 422 when unlock_all fails validation' do
        step_repo
        allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
        allow_any_instance_of(Step).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        post :unlock_all, params: { protocol_id: protocol_repo.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'logs unlock_all_protocol_steps when the last locked step is unlocked' do
        allow(Protocol).to receive(:content_locking_enabled?).and_return(true)
        step_repo.update!(locked: true)

        expect do
          post :unlock, params: { id: step_repo.id }, format: :json
        end.to change { Activity.where(type_of: :unlock_all_protocol_steps).count }.by(1)
        expect(step_repo.reload.locked).to be false
      end
    end

    describe 'POST update_view_state' do
      it 'stores the assets sort order' do
        post :update_view_state, params: { id: step.id, assets: { order: 'atoz' } }, format: :json

        expect(response).to have_http_status(:ok)
        expect(step.current_view_state(user).state['assets']['sort']).to eq 'atoz'
      end

      it 'returns 403 when user cannot manage the step' do
        allow(controller).to receive(:can_manage_step?).and_return(false)
        post :update_view_state, params: { id: step.id, assets: { order: 'atoz' } }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST update_asset_view_mode' do
      let!(:step_asset) { create :step_asset, step: step }

      it 'updates the step and its assets view mode' do
        post :update_asset_view_mode, params: { id: step.id, assets_view_mode: 'list' }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['view_mode']).to eq 'list'
        expect(step.reload.assets_view_mode).to eq 'list'
        expect(step_asset.asset.reload.view_mode).to eq 'list'
      end

      it 'returns 422 when update fails' do
        allow_any_instance_of(Step).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(step))
        post :update_asset_view_mode, params: { id: step.id, assets_view_mode: 'list' }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to be_present
      end
    end

    describe 'DELETE destroy permissions' do
      it 'returns 403 for active task step' do
        step
        expect do
          delete :destroy, params: { id: step.id }, format: :json
        end.not_to change(Step, :count)

        expect(response).to have_http_status(:forbidden)
      end

      it 'does not destroy a step with locked assets' do
        archived_step
        allow_any_instance_of(Step).to receive(:can_destroy?).and_return(false)
        expect do
          delete :destroy, params: { id: archived_step.id }, format: :json
        end.not_to change(Step, :count)

        expect(response).to have_http_status(:ok)
      end
    end

    describe 'POST toggle_step_state edge cases' do
      it 'returns 422 when save fails' do
        allow_any_instance_of(Step).to receive(:save).and_return(false)
        post :toggle_step_state, params: { id: step.id, completed: 'false' }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      # NOTE: check_complete_and_checkbox_permissions checks the permission matching the step's *current*
      # state (completed -> can_complete), i.e. the opposite of the transition being performed.
      it 'checks complete permission when uncompleting a completed step (current behaviour)' do
        allow(controller).to receive(:can_complete_my_module_steps?).and_return(false)
        post :toggle_step_state, params: { id: step.id, completed: 'false' }, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(step.reload.completed).to be true
      end

      it 'denies uncompleting when user lacks uncomplete permission' do
        pending 'bug: toggle_step_state checks can_complete when uncompleting (permission check inverted)'
        allow(controller).to receive(:can_uncomplete_my_module_steps?).and_return(false)
        post :toggle_step_state, params: { id: step.id, completed: 'false' }, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST toggle_step_skip_state' do
      it 'skips the step and logs activity' do
        expect do
          post :toggle_step_skip_state, params: { id: step.id, skipped: 'true' }, format: :json
        end.to change { Activity.where(type_of: :skip_step).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(step.reload.skipped_at).to be_present
        expect(step.completed).to be false
      end

      it 'unskips the step and logs activity' do
        step.update!(skipped_at: Time.zone.now, completed: false)

        expect do
          post :toggle_step_skip_state, params: { id: step.id, skipped: 'false' }, format: :json
        end.to change { Activity.where(type_of: :unskip_step).count }.by(1)

        expect(step.reload.skipped_at).to be_nil
      end

      it 'returns 422 when save fails' do
        allow_any_instance_of(Step).to receive(:save).and_return(false)
        post :toggle_step_skip_state, params: { id: step.id, skipped: 'true' }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns 403 when user cannot skip steps' do
        allow(controller).to receive(:can_skip_my_module_steps?).and_return(false)
        post :toggle_step_skip_state, params: { id: step.id, skipped: 'true' }, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(step.reload.skipped_at).to be_nil
      end
    end

    describe 'POST reorder' do
      it 'updates positions in task protocol and logs activity' do
        first = create :step, protocol: task_protocol, user: user, position: 0
        second = create :step, protocol: task_protocol, user: user, position: 1

        expect do
          post :reorder, params: { protocol_id: task_protocol.id,
                                   step_positions: { first.id.to_s => 1, second.id.to_s => 0 } }, as: :json
        end.to change { Activity.where(type_of: :task_steps_rearranged).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(first.reload.position).to eq 1
        expect(json['steps_order'].map { |s| s['id'] }).to eq [second.id, first.id]
      end

      it 'logs template activity in repository protocol' do
        first = create :step, protocol: protocol_repo, position: 0
        second = create :step, protocol: protocol_repo, position: 1

        expect do
          post :reorder, params: { protocol_id: protocol_repo.id,
                                   step_positions: { first.id.to_s => 1, second.id.to_s => 0 } }, as: :json
        end.to change { Activity.where(type_of: :protocol_steps_rearranged).count }.by(1)
      end

      it 'does not log activity when positions are unchanged' do
        first = create :step, protocol: task_protocol, user: user, position: 0

        expect do
          post :reorder, params: { protocol_id: task_protocol.id, step_positions: { first.id.to_s => 0 } }, as: :json
        end.not_to change(Activity, :count)
      end

      it 'returns 403 when reorder is not permitted' do
        allow(controller).to receive(:can_reorder_protocol_steps?).and_return(false)
        post :reorder, params: { protocol_id: task_protocol.id, step_positions: {} }, as: :json

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 403 when user cannot manage protocol' do
        allow(controller).to receive(:can_manage_protocol_in_module?).and_return(false)
        allow(controller).to receive(:can_manage_protocol_draft_in_repository?).and_return(false)
        post :reorder, params: { protocol_id: task_protocol.id, step_positions: {} }, as: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET list_protocol_steps' do
      it 'returns paginated steps filtered by query' do
        create :step, protocol: protocol_repo, position: 0, name: 'Mix reagents'
        create :step, protocol: protocol_repo, position: 1, name: 'Centrifuge'
        get :list_protocol_steps, params: { protocol_id: protocol_repo.id, query: 'Mix' }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['paginated']).to be true
        expect(json['data'].map { |d| d[1] }).to eq ['Mix reagents']
        expect(json['data'].first[2]).to eq('position' => 0)
      end
    end

    describe 'POST add_protocol_steps' do
      let(:source_protocol) { create :protocol, :in_repository_published_original, team: team, added_by: user }
      let!(:source_step) { create :step, protocol: source_protocol, position: 0, name: 'Source step' }

      it 'copies selected steps into task protocol and logs activity' do
        expect do
          post :add_protocol_steps, params: { protocol_id: task_protocol.id, selected_protocol: source_protocol.id,
                                              steps: [source_step.id] }, format: :json
        end.to change { task_protocol.steps.count }.by(1)
           .and change { Activity.where(type_of: :task_steps_loaded_from_template).count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(task_protocol.steps.pluck(:name)).to include 'Source step'
      end

      it 'copies selected steps into template draft and logs template activity' do
        expect do
          post :add_protocol_steps, params: { protocol_id: protocol_repo.id, selected_protocol: source_protocol.id,
                                              steps: [source_step.id] }, format: :json
        end.to change { Activity.where(type_of: :protocol_steps_loaded_from_template).count }.by(1)

        expect(protocol_repo.steps.pluck(:name)).to eq ['Source step']
      end

      it 'returns 403 when the source protocol is not readable' do
        pending 'bug: add_protocol_steps calls render_403 without return, then continues and raises DoubleRenderError'
        allow(controller).to receive(:can_read_protocol_in_repository?).and_call_original
        allow(controller).to receive(:can_read_protocol_in_repository?).with(source_protocol).and_return(false)

        expect do
          post :add_protocol_steps, params: { protocol_id: protocol_repo.id, selected_protocol: source_protocol.id,
                                              steps: [source_step.id] }, format: :json
        end.not_to change(Step, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 403 when user cannot manage the target protocol' do
        allow(controller).to receive(:can_manage_protocol_in_module?).and_return(false)
        allow(controller).to receive(:can_manage_protocol_draft_in_repository?).and_return(false)

        expect do
          post :add_protocol_steps, params: { protocol_id: task_protocol.id, selected_protocol: source_protocol.id,
                                              steps: [source_step.id] }, format: :json
        end.not_to change(Step, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
