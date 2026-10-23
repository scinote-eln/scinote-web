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

describe StepElements::TablesController, type: :controller do
  login_user

  include_context 'reference_project_structure', { record_deletion_enabled: true, step: true }

  let(:json) { JSON.parse(response.body) }
  let(:table) { create :table, team: team, name: 'Table one' }
  let!(:step_table) { create :step_table, step: step, table: table }
  let!(:table_element) { create :step_orderable_element, step: step, orderable: step_table, position: 0 }

  describe 'POST create' do
    let(:params) { { step_id: step.id, tableDimensions: %w(2 3) } }

    it 'creates a table with given dimensions and logs activity' do
      expect do
        post :create, params: params, format: :json
      end.to change { step.tables.count }.by(1)
         .and change { Activity.where(type_of: :task_step_table_added).count }.by(1)

      expect(response).to have_http_status(:ok)
      new_table = step.tables.order(:id).last
      expect(JSON.parse(new_table.contents)['data']).to eq [['', '', ''], ['', '', '']]
      expect(new_table.name).to eq I18n.t('protocols.steps.table.default_name', position: 2)
      expect(json['id']).to eq new_table.id
      expect(json['position']).to eq 1
    end

    it 'uses the plate default name for plate templates' do
      post :create, params: params.merge(plateTemplate: true), as: :json

      new_table = step.tables.order(:id).last
      expect(new_table.name).to eq I18n.t('protocols.steps.plate.default_name', position: 2)
      expect(new_table.metadata['plateTemplate']).to be true
    end

    it 'uses the given name' do
      post :create, params: params.merge(name: 'Custom'), format: :json

      expect(json['name']).to eq 'Custom'
    end

    it 'returns 422 when the table is invalid' do
      pending 'bug: invalid table is not validated by StepTable#save!, so create raises PG::NotNullViolation (500) instead of 422'
      expect do
        post :create, params: params.merge(name: 'a' * 300), format: :json
      end.not_to change(Table, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 when user cannot manage the step' do
      allow(controller).to receive(:can_manage_step?).and_return(false)
      post :create, params: params, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 for unknown step' do
      post :create, params: { step_id: -1, tableDimensions: %w(1 1) }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PATCH update' do
    it 'updates contents, merges metadata and logs activity' do
      table.update!(metadata: { 'existing' => 'yes' })
      new_contents = { data: [%w(x)] }.to_json

      expect do
        patch :update, params: { step_id: step.id, id: table.id, contents: new_contents,
                                 metadata: { 'cells' => 'abc' } }, format: :json
      end.to change { Activity.where(type_of: :task_step_table_edited).count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(table.reload.contents).to eq new_contents
      expect(table.metadata).to include('existing' => 'yes', 'cells' => 'abc')
      expect(json['contents']).to eq new_contents
    end

    it 'ignores JSON-string metadata (dropped by strong params, so the String branch is unreachable)' do
      table.update!(metadata: { 'existing' => 'yes' })
      patch :update, params: { step_id: step.id, id: table.id, metadata: { 'cells' => 'abc' }.to_json }, format: :json

      expect(response).to have_http_status(:ok)
      expect(table.reload.metadata).to eq('existing' => 'yes')
    end

    it 'does not log activity when nothing changed' do
      table.update_column(:last_modified_by_id, user.id)
      expect do
        patch :update, params: { step_id: step.id, id: table.id, name: table.name }, format: :json
      end.not_to change(Activity, :count)
    end

    it 'returns 422 for invalid name' do
      patch :update, params: { step_id: step.id, id: table.id, name: 'a' * 300 }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 for archived table' do
      table.update!(archived: true)
      patch :update, params: { step_id: step.id, id: table.id, name: 'x' }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 for unknown table' do
      patch :update, params: { step_id: step.id, id: -1, name: 'x' }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET move_targets' do
    it 'lists other active unlocked steps' do
      other = create :step, protocol: my_module.protocol, position: 5, name: 'Target'
      create :step, protocol: my_module.protocol, position: 6, locked: true

      get :move_targets, params: { step_id: step.id, id: table.id }, format: :json

      expect(json['targets']).to eq [[other.id, 'Target']]
    end
  end

  describe 'POST move' do
    let!(:target) { create :step, protocol: my_module.protocol, position: 5 }

    it 'moves the table to the target step and logs activity' do
      expect do
        post :move, params: { step_id: step.id, id: table.id, target_id: target.id }, format: :json
      end.to change { Activity.where(type_of: :task_step_table_moved).count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(step_table.reload.step).to eq target
      expect(table_element.reload.step).to eq target
    end

    it 'returns 422 when moving fails' do
      allow_any_instance_of(StepTable).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      post :move, params: { step_id: step.id, id: table.id, target_id: target.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(step_table.reload.step).to eq step
    end

    it 'returns 403 for archived table' do
      table.update!(archived: true)
      post :move, params: { step_id: step.id, id: table.id, target_id: target.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST duplicate' do
    it 'duplicates the table after the original' do
      following = create :step_orderable_element, step: step, position: 1
      expect do
        post :duplicate, params: { step_id: step.id, id: table.id }, format: :json
      end.to change { step.tables.count }.by(1)
         .and change { Activity.where(type_of: :task_step_table_duplicated).count }.by(1)

      expect(json['name']).to eq 'Table one (1)'
      expect(json['position']).to eq 1
      expect(following.reload.position).to eq 2
    end

    it 'returns 422 when duplication fails' do
      allow_any_instance_of(Table).to receive(:duplicate).and_raise(ActiveRecord::RecordInvalid)
      post :duplicate, params: { step_id: step.id, id: table.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST archive' do
    it 'archives the table and logs activity' do
      expect do
        post :archive, params: { step_id: step.id, id: table.id }, format: :json
      end.to change { Activity.where(type_of: :task_step_table_archived).count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(table.reload.archived).to be true
      expect(StepOrderableElement.exists?(table_element.id)).to be false
    end

    it 'returns a duplicate sheet name error when archiving fails' do
      allow_any_instance_of(Table).to receive(:archive!).and_raise(ActiveRecord::RecordInvalid.new(table))
      post :archive, params: { step_id: step.id, id: table.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      # NOTE: errors[:sheet_name] is always truthy ([]), so the sheet-name message is returned for any error
      expect(json['error']).to eq I18n.t('activerecord.errors.models.table.attributes.sheet_name.not_unique_in_context_long')
    end

    it 'returns a general error when archiving fails for another reason' do
      pending 'bug: BaseController#archive checks errors[:sheet_name] (always truthy array) instead of .any?'
      allow_any_instance_of(Table).to receive(:archive!).and_raise(ActiveRecord::RecordInvalid.new(table))
      post :archive, params: { step_id: step.id, id: table.id }, format: :json

      expect(json['error']).to eq I18n.t('general.error')
    end

    it 'returns 403 for template tables' do
      repo_protocol = create :protocol, :in_repository_draft, team: team, added_by: user
      repo_step = create :step, protocol: repo_protocol
      repo_table = create(:step_table, step: repo_step, table: create(:table, team: team)).table
      post :archive, params: { step_id: repo_step.id, id: repo_table.id }, format: :json

      expect(response).to have_http_status(:forbidden)
      expect(repo_table.reload.archived).to be false
    end
  end

  describe 'POST restore' do
    before { table.archive!(user) }

    it 'restores the table and logs activity' do
      expect do
        post :restore, params: { step_id: step.id, id: table.id }, format: :json
      end.to change { Activity.where(type_of: :task_step_table_restored).count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(table.reload.archived).to be false
      expect(step_table.reload.step_orderable_element).to be_present
    end

    it 'returns 422 when restore fails' do
      allow_any_instance_of(Table).to receive(:restore!).and_raise(ActiveRecord::RecordInvalid.new(table))
      post :restore, params: { step_id: step.id, id: table.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to be_present
    end

    it 'returns 403 for active table' do
      table.restore!(user)
      post :restore, params: { step_id: step.id, id: table.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE destroy' do
    it 'deletes an archived table and logs activity' do
      table.archive!(user)

      expect do
        delete :destroy, params: { step_id: step.id, id: table.id }, format: :json
      end.to change(Table, :count).by(-1)
         .and change { Activity.where(type_of: :task_step_table_deleted).count }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 when destroy fails' do
      table.archive!(user)
      allow_any_instance_of(Table).to receive(:destroy).and_return(false)
      delete :destroy, params: { step_id: step.id, id: table.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 403 for active task table' do
      expect do
        delete :destroy, params: { step_id: step.id, id: table.id }, format: :json
      end.not_to change(Table, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST lock' do
    it 'returns 422 when locking fails' do
      allow(controller).to receive(:can_lock_step_table?).and_return(true)
      allow_any_instance_of(Table).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      post :lock, params: { step_id: step.id, id: table.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 422 when unlocking fails' do
      allow(controller).to receive(:can_unlock_step_table?).and_return(true)
      allow_any_instance_of(Table).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      post :unlock, params: { step_id: step.id, id: table.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
