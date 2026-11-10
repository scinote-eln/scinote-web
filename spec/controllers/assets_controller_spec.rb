# frozen_string_literal: true

require 'rails_helper'

describe AssetsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    team_role: :owner,
    result_asset: true,
    step: true,
    steps: 2,
    step_asset: true,
    result_comment: true
  }

  let(:protocol_in_repository) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:step_in_repository) { create :step, protocol: protocol_in_repository, user: user }

  let!(:asset) { create :asset }
  let(:step_asset_in_repository) { create :step_asset, step: step_in_repository, asset: asset }

  let!(:archived_asset) { create :asset, archived: true, archived_by: user, archived_on: Time.zone.now }

  let(:archived_step_asset) { create :step_asset, step: step_asset.step, asset: archived_asset }
  let(:archived_result_asset) { create :result_asset, result: result_asset.result, asset: archived_asset }

  def expect_success_json
    expect(response).to have_http_status(:success)
    expect(response.media_type).to eq('application/json')
    expect(response.body).to be_present
  end

  def expect_unprocessable_json
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.media_type).to eq('application/json')
    expect(response.body).to be_present
  end

  describe 'GET #file_preview' do
    let(:action) { get :file_preview, params: { id: step_asset.asset.id }, format: :json }

    it 'file preview returned' do
      action
      expect_success_json
    end
  end

  describe 'PATCH #toggle_view_mode' do
    let(:action) { patch :toggle_view_mode, params: { id: step_asset.asset.id, asset: {view_mode: 'inline'} }, format: :json }

    it 'change asset view mode' do
      action
      expect_success_json
    end
  end

   describe 'GET #load_asset' do
    let(:action) { get :load_asset, params: { id: asset_id }, format: :json }

    context 'when step asset' do
      let(:asset_id) { step_asset.asset.id }
      it 'succesfully load asset' do
        action
        expect_success_json
      end
    end

    context 'when result asset' do
      let(:asset_id) { result_asset.asset.id }
      it 'succesfully load asset' do
        action
        expect_success_json
      end
    end
  end

  describe 'GET #move_targets' do
    let(:action) { get :move_targets, params: { id: asset_id }, format: :json }

    context 'when step asset' do
      let(:asset_id) { step_asset.asset.id }
      it 'succesfully load' do
        action
        expect_success_json
      end
    end

    context 'when #result asset' do
      let(:asset_id) { result_asset.asset.id }
      it 'succesfully load' do
        action
        expect_success_json
      end
    end
  end

   describe 'POST #move' do
    let(:action) { post :move, params: { id: asset_id, target_id: target_id}, format: :json }

    context 'when step asset' do
      let(:asset_id) { step_asset.asset.id }
      let(:target_id) { steps.first.id }
      it 'succesfully move' do
        action
        expect_success_json
      end
    end

    context 'when result asset' do
      let(:result1) { create :result, my_module: step.my_module, user: user }
      let(:asset_id) { result_asset.asset.id }
      let(:target_id) { result1.id }
      it 'succesfully move' do
        action
        expect_success_json
      end
    end

    context 'when protocol template asset' do
      let(:step_in_repository1) { create :step, protocol: protocol_in_repository, user: user }
      let(:asset_id) { step_asset_in_repository.asset.id }
      let(:target_id) { step_in_repository1.id }
      it 'succesfully move' do
        action
        expect_success_json
      end
    end

    context 'when the user is a viewer (can read but not manage)' do
      let(:target_step) { steps.first }
      let(:target_result) { create :result, my_module: my_module, user: user }

      before do
        # create every record (and its owner assignment) first, then downgrade all assignments of the user
        step_asset
        result_asset
        step_asset_in_repository
        target_step
        target_result
        UserAssignment.where(user: user).update_all(user_role_id: viewer_role.id)
      end

      it 'has only viewer assignments left, so inherited owner rights are gone' do
        expect(UserAssignment.where(user: user).pluck(:user_role_id).uniq).to eq([viewer_role.id])
        [team, project, experiment, my_module, protocol_in_repository].each do |assignable|
          assignment = UserAssignment.find_by(user: user, assignable: assignable)
          expect(assignment&.user_role).to eq(viewer_role)
        end
      end

      context 'when moving a step asset to another step' do
        let(:asset_id) { step_asset.asset.id }
        let(:target_id) { target_step.id }

        it 'renders 403 and leaves the asset on its step' do
          original_step_id = step_asset.step_id

          action

          expect(response).to have_http_status(:forbidden)
          expect(step_asset.reload.step_id).to eq(original_step_id)
          expect(step_asset.step_id).not_to eq(target_step.id)
        end
      end

      context 'when moving a result asset to another result' do
        let(:asset_id) { result_asset.asset.id }
        let(:target_id) { target_result.id }

        it 'renders 403 and leaves the asset on its result' do
          original_result_id = result_asset.result_id

          action

          expect(response).to have_http_status(:forbidden)
          expect(result_asset.reload.result_id).to eq(original_result_id)
          expect(result_asset.result_id).not_to eq(target_result.id)
        end
      end

      context 'when moving an asset of a protocol in the repository' do
        let(:step_in_repository1) { create :step, protocol: protocol_in_repository, user: user }
        let(:asset_id) { step_asset_in_repository.asset.id }
        let(:target_id) { step_in_repository1.id }

        before { step_in_repository1 }

        it 'renders 403 and leaves the asset on its step' do
          original_step_id = step_asset_in_repository.step_id

          action

          expect(response).to have_http_status(:forbidden)
          expect(step_asset_in_repository.reload.step_id).to eq(original_step_id)
          expect(step_asset_in_repository.step_id).not_to eq(step_in_repository1.id)
        end
      end

      # move_targets stays read-gated: proves the downgrade leaves read access intact
      context 'when requesting move targets of a step asset' do
        let(:action) { get :move_targets, params: { id: step_asset.asset.id }, format: :json }

        it 'still returns the targets' do
          action

          expect_success_json
          target_ids = response.parsed_body['targets'].map(&:first)
          expect(target_ids).to include(*steps.map(&:id))
          expect(target_ids).not_to include(step_asset.step_id)
        end
      end
    end

    context 'when the target is not manageable' do
      let(:target_result) { create :result, my_module: my_module, user: user }

      context 'when the target step has locked attachments' do
        let(:asset_id) { step_asset.asset.id }
        let(:target_id) { steps.first.id }

        it 'renders 403 and leaves the asset on its step' do
          steps.first.update_column(:attachments_locked, true)
          original_step_id = step_asset.step_id

          action

          expect(response).to have_http_status(:forbidden)
          expect(step_asset.reload.step_id).to eq(original_step_id)
          expect(step_asset.step_id).not_to eq(steps.first.id)
        end
      end

      context 'when the target result has locked attachments' do
        let(:asset_id) { result_asset.asset.id }
        let(:target_id) { target_result.id }

        it 'renders 403 and leaves the asset on its result' do
          target_result.update_column(:attachments_locked, true)
          original_result_id = result_asset.result_id

          action

          expect(response).to have_http_status(:forbidden)
          expect(result_asset.reload.result_id).to eq(original_result_id)
          expect(result_asset.result_id).not_to eq(target_result.id)
        end
      end

      context 'when the target step is archived' do
        let(:archived_target_step) do
          create :step, protocol: my_module.protocol, user: user, archived: true, archived_by: user,
                        archived_on: Time.zone.now
        end
        let(:asset_id) { step_asset.asset.id }
        let(:target_id) { archived_target_step.id }

        it 'renders 403 and leaves the asset on its step' do
          original_step_id = step_asset.step_id

          action

          expect(response).to have_http_status(:forbidden)
          expect(step_asset.reload.step_id).to eq(original_step_id)
          expect(step_asset.step_id).not_to eq(archived_target_step.id)
        end
      end
    end
  end

  describe 'GET #file_url' do
    let(:action) { get :file_url, params: { id: step_asset.asset.id } }

    it 'file url returned' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/plain'
      expect(response.body).not_to be_empty
    end
  end

  describe 'GET #download' do
    let(:action) { get :download, params: { id: step_asset.asset.id } }

    it 'file download url returned' do
      action
      expect(response).to have_http_status(:redirect)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'GET #show' do
    let(:action) { get :show, params: { id: step_asset.asset.id } }

    it 'file show' do
      action
      expect_success_json
    end
  end

  describe 'POST #create_wopi_file' do
    let(:action) { post :create_wopi_file, params: { element_id: element_id, element_type: element_type,
                                                     file_type: 'docx', file_name: Faker::Name.unique.name } }

    context 'when in task step' do
      let(:element_type) { 'Step' }
      let(:element_id) { step_asset.step }
      it 'create wopi file' do
        action
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_type) { 'Result' }
      let(:element_id) { result_asset.result }
      it 'create wopi file' do
        action
        expect_success_json
      end
    end
  end

  describe 'PATCH #rename' do
    let(:action) { patch :rename, params: { id: element_id, asset: { name: asset_name } } }

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      let(:asset_name) { Faker::Name.unique.name }
      it 'rename file' do
        action
        expect_success_json
      end
    end

    context 'when in #empty name' do
      let(:element_id) { step_asset.asset.id }
      let(:asset_name) { '' }
      it 'rename file' do
        action
        expect_unprocessable_json
      end
    end

    context 'when to long name' do
      let(:element_id) { step_asset.asset.id }
      let(:asset_name) { Faker::Lorem.characters(number: Constants::NAME_MAX_LENGTH + 1) }
      it 'rename file' do
        action
        expect_unprocessable_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      let(:asset_name) { Faker::Name.unique.name }
      it 'rename file' do
        action
        expect_success_json
      end
    end
  end

  describe 'PATCH #update_title' do
    let(:action) { patch :update_title, params: { id: element_id, asset: { file_title: new_title } }, format: :json }
    let(:new_title) { Faker::Name.unique.name }

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }

      it 'updates the file title' do
        expect { action }.to change(Activity, :count).by(1)
        expect_success_json
        expect(step_asset.asset.reload.file_title).to eq(new_title)
        expect(Activity.last.type_of).to eq('task_step_asset_title_changed')
      end
    end

    context 'when in protocol step (protocol repository)' do
      let(:element_id) { step_asset_in_repository.asset.id }

      it 'updates the file title' do
        expect { action }.to change(Activity, :count).by(1)
        expect_success_json
        expect(Activity.last.type_of).to eq('protocol_step_asset_title_changed')
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }

      it 'updates the file title' do
        expect { action }.to change(Activity, :count).by(1)
        expect_success_json
        expect(Activity.last.type_of).to eq('result_asset_title_changed')
      end
    end

    context 'when on an inventory item' do
      let(:repository) { create :repository, team: team, created_by: user }
      let(:repository_row) { create :repository_row, repository: repository }
      let(:repository_cell) { create :repository_cell, :asset_value, repository_row: repository_row }
      let(:element_id) { repository_cell.value.asset.id }

      before { user.update(current_team_id: team.id) }

      it 'updates the file title' do
        expect { action }.to change(Activity, :count).by(1)
        expect_success_json
        expect(Activity.last.type_of).to eq('item_asset_title_changed')
      end
    end
  end

  describe 'POST #update_image' do
    let(:action) { post :update_image, params: { id: element_id, image: fixture_file_upload(Rails.root.join('spec/fixtures/files/apple.jpg'), 'image/jpeg') } }

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      it 'update image' do
        action
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      it 'update image' do
        action
        expect_success_json
      end
    end

    context 'when in task step with locked attachments' do
      let(:element_id) { step_asset.asset.id }
      it 'cannot update image' do
        step_asset.step.update_column(:attachments_locked, true)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when in task result with locked attachments' do
      let(:element_id) { result_asset.asset.id }
      it 'cannot update image' do
        result_asset.result.update_column(:attachments_locked, true)
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET #versions' do
    let(:action) { get :versions, params: { id: step_asset.asset.id } }

    it 'file versions returned' do
      action
      expect_success_json
    end
  end

  describe 'POST #duplicate' do
    let(:action) { post :duplicate, params: { id: element_id } }

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      it 'duplicate' do
        action
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      it 'duplicate' do
        action
        expect_success_json
      end
    end
  end

  describe 'POST #restore_version' do
    let(:action) { post :restore_version, params: { id: element_id, version: 1 } }

    before do
      allow_any_instance_of(Asset).to receive(:restore_file_version).and_return(true)
      allow(VersionedAttachments).to receive(:enabled?).and_return(true)
    end

    context 'when in task step' do
      let(:element_id) { step_asset.asset.id }
      it 'restore version' do
        action
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_id) { result_asset.asset.id }
      it 'restore version' do
        action
        expect_success_json
      end
    end

    context 'when in protocol' do
      let(:element_id) { step_asset_in_repository.asset.id }
      it 'restore version' do
        action
        expect_success_json
      end
    end
  end


  describe 'POST #start_edit' do
    before do
      allow(controller).to receive(:check_manage_permission).and_return(true)
    end
    let(:action) { post :create_start_edit_image_activity, params: params, format: :json }
    let!(:params) do
      { id: nil }
    end
    it 'calls create activity service (start edit image on step)' do
      params[:id] = step_asset.asset.id
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_image_on_step))
      action
    end

    it 'calls create activity service (start edit image on result)' do
      params[:id] = result_asset.asset.id
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_image_on_result))
      action
    end

    it 'calls create activity service (start edit image on step in repository)' do
      params[:id] = step_asset_in_repository.asset.id
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_image_on_step_in_repository))
      action
    end

    it 'adds activity in DB' do
      params[:id] = step_asset.asset.id
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE #destroy' do
    let(:action) { delete :destroy, params: { id: element_id } }

    context 'when in task step' do
      let(:element_id) { archived_step_asset.asset.id }
      it 'destroy' do
        action
        expect_success_json
      end
    end

    context 'when in task result' do
      let(:element_id) { archived_result_asset.asset.id }
      it 'destroy' do
        action
        expect_success_json
      end
    end
  end

  describe 'POST #lock' do
    let(:action) { post :lock, params: { id: step_asset_in_repository.asset.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_lock_asset?).and_return(true) }

      it 'locks the asset' do
        action
        expect(response).to have_http_status(:ok)
        expect(step_asset_in_repository.asset.reload.locked).to be true
      end

      it 'logs a file lock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :lock_protocol_step_file)))
        action
      end

      it 'does not log an activity when the asset is already locked' do
        step_asset_in_repository.asset.update!(locked: true)
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService).not_to have_received(:call)
      end
    end

    context 'when locking a result asset' do
      let(:action) { post :lock, params: { id: result_asset.asset.id } }

      before { allow(controller).to receive(:can_lock_asset?).and_return(true) }

      it 'does not log a step file lock activity' do
        allow(Activities::CreateActivityService).to receive(:call)
        action
        expect(Activities::CreateActivityService).not_to have_received(:call)
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_lock_asset?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST #unlock' do
    before { step_asset_in_repository.asset.update!(locked: true) }

    let(:action) { post :unlock, params: { id: step_asset_in_repository.asset.id } }

    context 'when user has permissions' do
      before { allow(controller).to receive(:can_unlock_asset?).and_return(true) }

      it 'unlocks the asset' do
        action
        expect(response).to have_http_status(:ok)
        expect(step_asset_in_repository.asset.reload.locked).to be false
      end

      it 'logs a file unlock activity' do
        expect(Activities::CreateActivityService)
          .to(receive(:call).with(hash_including(activity_type: :unlock_protocol_step_file)))
        action
      end
    end

    context 'when user lacks permissions' do
      before { allow(controller).to receive(:can_unlock_asset?).and_return(false) }

      it 'returns forbidden' do
        action
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  describe 'coverage of remaining branches' do
    let(:result_template) { create :result_template, protocol: protocol_in_repository, user: user }
    let(:result_template_asset) do
      create :result_asset, result: result_template, asset: create(:asset, team: team)
    end

    def set_asset_type(asset, type)
      asset.file.blob.update!(metadata: asset.file.blob.metadata.merge('asset_type' => type))
    end

    def downgrade_to_viewer(assignable)
      UserAssignment.where(user: user, assignable: assignable).update_all(user_role_id: viewer_role.id)
    end

    def remove_access(assignable)
      UserAssignment.where(user: user, assignable: assignable).destroy_all
    end

    describe 'GET #file_preview' do
      it 'returns rendered preview html' do
        get :file_preview, params: { id: step_asset.asset.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('html')
      end

      it 'returns 404 for unknown asset' do
        get :file_preview, params: { id: -1 }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns forbidden when user has no access to the task' do
        step_asset
        remove_access(my_module)
        get :file_preview, params: { id: step_asset.asset.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PATCH #toggle_view_mode' do
      it 'updates the view mode' do
        patch :toggle_view_mode, params: { id: step_asset.asset.id, asset: { view_mode: 'list' } }, format: :json
        expect(response).to have_http_status(:ok)
        expect(step_asset.asset.reload.view_mode).to eq 'list'
      end

      it 'is forbidden for viewers' do
        step_asset
        downgrade_to_viewer(my_module)
        patch :toggle_view_mode, params: { id: step_asset.asset.id, asset: { view_mode: 'list' } }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(step_asset.asset.reload.view_mode).not_to eq 'list'
      end
    end

    describe 'GET #move_targets' do
      it 'lists other result templates of the protocol' do
        other_template = create :result_template, protocol: protocol_in_repository, user: user
        get :move_targets, params: { id: result_template_asset.asset.id }, format: :json
        expect(response.parsed_body['targets']).to eq [[other_template.id, other_template.name]]
      end

      it 'excludes locked steps when protocol is in a task' do
        unlocked = create :step, protocol: my_module.protocol, user: user
        create :step, protocol: my_module.protocol, user: user, attachments_locked: true
        get :move_targets, params: { id: step_asset.asset.id }, format: :json
        expect(response.parsed_body['targets'].map(&:first)).to eq [unlocked.id]
      end
    end

    describe 'POST #move' do
      it 'moves asset between result templates and logs activity' do
        target = create :result_template, protocol: protocol_in_repository, user: user
        asset_id = result_template_asset.asset.id
        expect do
          post :move, params: { id: asset_id, target_id: target.id }, format: :json
        end.to change(Activity, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(Asset.find(asset_id).result).to eq target
        expect(Activity.last.type_of).to eq 'result_template_file_moved'
      end

      it 'logs sequence activity when moving gene sequence between result templates' do
        target = create :result_template, protocol: protocol_in_repository, user: user
        set_asset_type(result_template_asset.asset, 'gene_sequence')
        post :move, params: { id: result_template_asset.asset.id, target_id: target.id }, format: :json
        expect(Activity.last.type_of).to eq 'sequence_on_result_template_moved'
      end

      it 'logs chemical structure activity when moving marvinjs asset between results' do
        target = create :result, my_module: my_module, user: user
        set_asset_type(result_asset.asset, 'marvinjs')
        post :move, params: { id: result_asset.asset.id, target_id: target.id }, format: :json
        expect(result_asset.reload.result_id).to eq target.id
        expect(Activity.last.type_of).to eq 'move_chemical_structure_on_result'
      end

      it 'logs chemical structure activity when moving marvinjs asset between steps' do
        target = steps.first
        set_asset_type(step_asset.asset, 'marvinjs')
        post :move, params: { id: step_asset.asset.id, target_id: target.id }, format: :json
        expect(step_asset.reload.step_id).to eq target.id
        expect(Activity.last.type_of).to eq 'move_chemical_structure_on_step'
      end

      it 'returns 404 when result target does not exist' do
        post :move, params: { id: result_asset.asset.id, target_id: -1 }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 when step target does not exist' do
        post :move, params: { id: step_asset.asset.id, target_id: -1 }, format: :json
        expect(response).to have_http_status(:not_found)
        expect(step_asset.reload.step_id).to eq step.id
      end

      it 'returns forbidden for viewers' do
        step_asset
        downgrade_to_viewer(my_module)
        post :move, params: { id: step_asset.asset.id, target_id: steps.first.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(step_asset.reload.step_id).to eq step.id
      end

      it 'returns forbidden when user has no access to the task' do
        step_asset
        remove_access(my_module)
        post :move, params: { id: step_asset.asset.id, target_id: steps.first.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(step_asset.reload.step_id).to eq step.id
      end
    end

    describe 'GET #file_url' do
      it 'returns forbidden without read access' do
        step_asset
        remove_access(my_module)
        get :file_url, params: { id: step_asset.asset.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET #edit and GET #view' do
      before do
        allow_any_instance_of(Asset).to receive(:get_action_url).and_return('https://wopi.test/edit?ui=en')
        allow_any_instance_of(Asset).to receive(:favicon_url).and_return('https://wopi.test/favicon.ico')
      end

      it 'prepares wopi edit page, creates a token and logs activity' do
        expect do
          get :edit, params: { id: step_asset.asset.id, wdOrigin: 'x', wdPreviousSession: 'y' }
        end.to change(Token, :count).by(1).and change(Activity, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(assigns(:action_url)).to eq 'https://wopi.test/edit?ui=en&wdOrigin=x'
        expect(assigns(:favicon_url)).to eq 'https://wopi.test/favicon.ico'
        expect(assigns(:token)).to eq Token.last.token
        expect(Activity.last.type_of).to eq 'edit_wopi_file_on_step'
      end

      it 'forbids edit for viewers' do
        step_asset
        downgrade_to_viewer(my_module)
        get :edit, params: { id: step_asset.asset.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'prepares wopi view page' do
        expect do
          get :view, params: { id: result_asset.asset.id }
        end.to change(Token, :count).by(1)
        expect(response).to have_http_status(:ok)
        expect(assigns(:action_url)).to start_with 'https://wopi.test/edit?ui=en&'
      end

      it 'forbids view without read access' do
        result_asset
        remove_access(my_module)
        get :view, params: { id: result_asset.asset.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET #pdf_preview' do
      it 'returns not acceptable for non previewable files' do
        get :pdf_preview, params: { id: step_asset.asset.id }
        expect(response).to have_http_status(:not_acceptable)
      end

      it 'returns accepted while preview is not ready' do
        allow_any_instance_of(AssetsController).to receive(:previewable_document?).and_return(true)
        allow_any_instance_of(Asset).to receive(:pdf_preview_ready?).and_return(false)
        get :pdf_preview, params: { id: step_asset.asset.id }
        expect(response).to have_http_status(:accepted)
      end
    end

    describe 'POST #update_image' do
      it 'renders asset link for result template assets' do
        post :update_image, params: {
          id: result_template_asset.asset.id,
          image: fixture_file_upload(Rails.root.join('spec/fixtures/files/apple.jpg'), 'image/jpeg')
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to have_key('html')
        expect(Activity.last.type_of).to eq 'edit_image_on_result_template'
      end

      it 'is forbidden for viewers' do
        step_asset
        downgrade_to_viewer(my_module)
        post :update_image, params: {
          id: step_asset.asset.id,
          image: fixture_file_upload(Rails.root.join('spec/fixtures/files/apple.jpg'), 'image/jpeg')
        }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST #create_wopi_file' do
      def create_wopi(element_type, element_id, file_type: 'docx', file_name: 'Document')
        post :create_wopi_file, params: { element_type: element_type, element_id: element_id,
                                          file_type: file_type, file_name: file_name }
      end

      it 'creates an empty wopi asset on a result template' do
        expect { create_wopi('ResultTemplate', result_template.id) }.to change(Asset, :count).by(1)
        asset = Asset.last
        expect(asset.version).to eq 0
        expect(asset.file_name).to eq 'Document.docx'
        expect(result_template.reload.assets).to include(asset)
      end

      it 'rejects unsupported file types' do
        expect { create_wopi('Step', step.id, file_type: 'exe') }.not_to change(Asset, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'rejects unsupported element types' do
        expect { create_wopi('Protocol', protocol_in_repository.id) }.not_to change(Asset, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'rejects blank file names' do
        expect { create_wopi('Step', step.id, file_name: '') }.not_to change(Asset, :count)
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body['message']).to have_key('file')
      end

      it 'is forbidden for viewers' do
        step
        downgrade_to_viewer(my_module)
        expect { create_wopi('Step', step.id) }.not_to change(Asset, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'DELETE #destroy' do
      it 'deletes result template asset and logs activity' do
        asset_id = result_template_asset.asset.id
        expect { delete :destroy, params: { id: asset_id } }.to change(Asset, :count).by(-1)
        expect(response.parsed_body['flash']).to be_present
        expect(Activity.last.type_of).to eq 'result_template_file_deleted'
        expect(Activity.last.values.dig('message_items', 'protocol', 'id')).to eq protocol_in_repository.id
      end

      it 'logs sequence deletion for gene sequence on result template' do
        set_asset_type(result_template_asset.asset, 'gene_sequence')
        delete :destroy, params: { id: result_template_asset.asset.id }
        expect(Activity.last.type_of).to eq 'sequence_on_result_template_deleted'
      end

      it 'logs chemical structure deletion for marvinjs on result template' do
        set_asset_type(result_template_asset.asset, 'marvinjs')
        delete :destroy, params: { id: result_template_asset.asset.id }
        expect(Activity.last.type_of).to eq 'delete_chemical_structure_on_result_template'
      end

      it 'logs sequence deletion for gene sequence on task step' do
        set_asset_type(archived_step_asset.asset, 'gene_sequence')
        delete :destroy, params: { id: archived_step_asset.asset.id }
        expect(Activity.last.type_of).to eq 'task_sequence_asset_deleted'
      end

      it 'logs chemical structure deletion for marvinjs on task step' do
        set_asset_type(archived_step_asset.asset, 'marvinjs')
        delete :destroy, params: { id: archived_step_asset.asset.id }
        expect(Activity.last.type_of).to eq 'delete_chemical_structure_on_step'
      end

      it 'logs file deletion for step in protocol template' do
        delete :destroy, params: { id: step_asset_in_repository.asset.id }
        expect(Activity.last.type_of).to eq 'protocol_step_file_deleted'
      end

      it 'logs chemical structure deletion for marvinjs on result' do
        set_asset_type(archived_result_asset.asset, 'marvinjs')
        delete :destroy, params: { id: archived_result_asset.asset.id }
        expect(Activity.last.type_of).to eq 'delete_chemical_structure_on_result'
      end

      it 'logs sequence deletion for gene sequence on result' do
        set_asset_type(archived_result_asset.asset, 'gene_sequence')
        delete :destroy, params: { id: archived_result_asset.asset.id }
        expect(Activity.last.type_of).to eq 'sequence_on_result_deleted'
      end

      it 'returns unprocessable entity when destroy fails' do
        allow_any_instance_of(Asset).to receive(:destroy).and_return(false)
        delete :destroy, params: { id: archived_step_asset.asset.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'is forbidden for active task assets' do
        step_asset
        expect { delete :destroy, params: { id: step_asset.asset.id } }.not_to change(Asset, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PATCH #rename' do
      it 'renames result template asset and logs activity' do
        patch :rename, params: { id: result_template_asset.asset.id, asset: { name: 'renamed.jpg' } }
        expect(response).to have_http_status(:ok)
        expect(result_template_asset.asset.reload.file_name).to eq 'renamed.jpg'
        expect(Activity.last.type_of).to eq 'result_template_asset_renamed'
      end

      it 'is forbidden for viewers' do
        step_asset
        downgrade_to_viewer(my_module)
        patch :rename, params: { id: step_asset.asset.id, asset: { name: 'renamed.jpg' } }
        expect(response).to have_http_status(:forbidden)
        expect(step_asset.asset.reload.file_name).to eq 'test.jpg'
      end
    end

    describe 'POST #duplicate' do
      it 'duplicates result template asset and logs activity' do
        result_template_asset
        expect { post :duplicate, params: { id: result_template_asset.asset.id } }
          .to change { result_template.reload.assets.count }.by(1)
        expect(response.parsed_body.dig('data', 'attributes', 'file_name')).to eq 'test (1).jpg'
        expect(Activity.last.type_of).to eq 'result_template_file_duplicated'
      end

      it 'is forbidden for viewers' do
        step_asset
        downgrade_to_viewer(my_module)
        expect { post :duplicate, params: { id: step_asset.asset.id } }.not_to change(Asset, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST #restore_version' do
      before do
        allow_any_instance_of(Asset).to receive(:restore_file_version).and_return(true)
        allow(VersionedAttachments).to receive(:enabled?).and_return(true)
      end

      it 'logs restore activity for result template asset' do
        post :restore_version, params: { id: result_template_asset.asset.id, version: 2 }
        expect(response).to have_http_status(:ok)
        expect(Activity.last.type_of).to eq 'result_template_restore_asset_version'
        expect(Activity.last.values['message_items']['version'].to_i).to eq 2
      end

      it 'is forbidden when versioning is disabled' do
        allow(VersionedAttachments).to receive(:enabled?).and_return(false)
        post :restore_version, params: { id: step_asset.asset.id, version: 1 }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST #archive' do
      it 'archives step file and logs activity' do
        post :archive, params: { id: step_asset.asset.id }
        expect(response).to have_http_status(:ok)
        expect(step_asset.asset.reload).to be_archived
        expect(Activity.last.type_of).to eq 'task_step_file_archived'
      end

      it 'logs sequence activity when archiving gene sequence on step' do
        set_asset_type(step_asset.asset, 'gene_sequence')
        post :archive, params: { id: step_asset.asset.id }
        expect(Activity.last.type_of).to eq 'task_step_sequence_archived'
      end

      it 'logs chemical structure activity when archiving marvinjs on step' do
        set_asset_type(step_asset.asset, 'marvinjs')
        post :archive, params: { id: step_asset.asset.id }
        expect(Activity.last.type_of).to eq 'task_step_chemical_structure_archived'
      end

      it 'archives result file and logs activity' do
        post :archive, params: { id: result_asset.asset.id }
        expect(result_asset.asset.reload).to be_archived
        expect(Activity.last.type_of).to eq 'result_file_archived'
      end

      it 'logs sequence activity when archiving gene sequence on result' do
        set_asset_type(result_asset.asset, 'gene_sequence')
        post :archive, params: { id: result_asset.asset.id }
        expect(Activity.last.type_of).to eq 'result_sequence_archived'
      end

      it 'logs chemical structure activity when archiving marvinjs on result' do
        set_asset_type(result_asset.asset, 'marvinjs')
        post :archive, params: { id: result_asset.asset.id }
        expect(Activity.last.type_of).to eq 'result_chemical_structure_archived'
      end

      it 'returns errors when archiving fails' do
        allow_any_instance_of(Asset).to receive(:archive).and_return(false)
        post :archive, params: { id: step_asset.asset.id }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to have_key('errors')
      end

      it 'is forbidden for viewers' do
        step_asset
        downgrade_to_viewer(my_module)
        post :archive, params: { id: step_asset.asset.id }
        expect(response).to have_http_status(:forbidden)
        expect(step_asset.asset.reload).not_to be_archived
      end
    end

    describe 'POST #restore' do
      it 'restores step file and logs activity' do
        post :restore, params: { id: archived_step_asset.asset.id }
        expect(response).to have_http_status(:ok)
        expect(archived_step_asset.asset.reload).not_to be_archived
        expect(Activity.last.type_of).to eq 'task_step_file_restored'
      end

      it 'logs sequence activity when restoring gene sequence on step' do
        set_asset_type(archived_step_asset.asset, 'gene_sequence')
        post :restore, params: { id: archived_step_asset.asset.id }
        expect(Activity.last.type_of).to eq 'task_step_sequence_restored'
      end

      it 'logs chemical structure activity when restoring marvinjs on step' do
        set_asset_type(archived_step_asset.asset, 'marvinjs')
        post :restore, params: { id: archived_step_asset.asset.id }
        expect(Activity.last.type_of).to eq 'task_step_chemical_structure_restored'
      end

      it 'restores result file and logs activity' do
        post :restore, params: { id: archived_result_asset.asset.id }
        expect(archived_result_asset.asset.reload).not_to be_archived
        expect(Activity.last.type_of).to eq 'result_file_restored'
      end

      it 'logs sequence activity when restoring gene sequence on result' do
        set_asset_type(archived_result_asset.asset, 'gene_sequence')
        post :restore, params: { id: archived_result_asset.asset.id }
        expect(Activity.last.type_of).to eq 'result_sequence_restored'
      end

      it 'logs chemical structure activity when restoring marvinjs on result' do
        set_asset_type(archived_result_asset.asset, 'marvinjs')
        post :restore, params: { id: archived_result_asset.asset.id }
        expect(Activity.last.type_of).to eq 'result_chemical_structure_restored'
      end

      it 'returns errors when restoring fails' do
        allow_any_instance_of(Asset).to receive(:restore).and_return(false)
        post :restore, params: { id: archived_step_asset.asset.id }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'is forbidden for active assets' do
        post :restore, params: { id: step_asset.asset.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
