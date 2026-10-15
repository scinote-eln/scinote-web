# frozen_string_literal: true

require 'rails_helper'

describe GeneSequenceAssetsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    step: true,
    step_asset: true,
    result_asset: true
  }

  let(:protocol_in_repository) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:step_in_repository) { create :step, protocol: protocol_in_repository, user: user }
  let(:result_template) { create :result_template, protocol: protocol_in_repository, user: user }
  let(:result_template_asset) do
    create :result_asset, result: result_template, asset: create(:asset, team: team)
  end

  let(:base64_image) do
    "data:image/png;base64,#{Base64.strict_encode64(File.binread(Rails.root.join('spec/fixtures/files/apple.jpg')))}"
  end
  let(:sequence_params) do
    {
      sequence_name: 'pUC19',
      sequence_data: { sequence: 'ATGC', circular: true },
      base64_image: base64_image
    }
  end

  before do
    allow(OpenVectorEditorService).to receive(:enabled?).and_return(true)
  end

  def downgrade_to_viewer(assignable)
    UserAssignment.where(user: user, assignable: assignable).update_all(user_role_id: viewer_role.id)
  end

  describe 'GET #new' do
    it 'renders the editor for a step the user can manage' do
      get :new, params: { parent_type: 'Step', parent_id: step.id }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:edit)
      expect(assigns(:parent)).to eq step
      expect(assigns(:protocol)).to eq step.protocol
    end

    it 'renders the editor for a result' do
      get :new, params: { parent_type: 'Result', parent_id: result_asset.result.id }
      expect(response).to have_http_status(:ok)
      expect(assigns(:result)).to eq result_asset.result
    end

    it 'is forbidden for unknown parent' do
      get :new, params: { parent_type: 'Experiment', parent_id: experiment.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden for viewers' do
      step
      downgrade_to_viewer(my_module)
      get :new, params: { parent_type: 'Step', parent_id: step.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET #edit' do
    it 'renders the editor and logs edit started activity for a task step' do
      expect { get :edit, params: { id: step_asset.asset.id } }.to change(Activity, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(assigns(:file_name)).to eq 'test.jpg'
      expect(assigns(:file_url)).to be_present
      expect(Activity.last.type_of).to eq 'task_sequence_asset_edit_started'
    end

    it 'logs protocol activity for a step in a protocol template' do
      asset = create(:step_asset, step: step_in_repository).asset
      get :edit, params: { id: asset.id }
      expect(Activity.last.type_of).to eq 'protocol_sequence_asset_edit_started'
    end

    it 'logs result template activity' do
      get :edit, params: { id: result_template_asset.asset.id }
      expect(Activity.last.type_of).to eq 'sequence_on_result_template_edited'
    end

    it 'does not log activity for results' do
      result_asset
      expect { get :edit, params: { id: result_asset.asset.id } }.not_to change(Activity, :count)
      expect(response).to have_http_status(:ok)
    end

    it 'returns not found for asset from another team' do
      get :edit, params: { id: create(:asset).id }
      expect(response).to have_http_status(:not_found)
    end

    it 'does not render the editor without read access' do
      # check_read_permission renders 403 for the asset and then again for the parent,
      # which raises a double render error instead of a clean 403 response
      step_asset
      UserAssignment.where(user: user, assignable: my_module).destroy_all
      expect { get :edit, params: { id: step_asset.asset.id } }.to raise_error(AbstractController::DoubleRenderError)
    end
  end

  describe 'POST #create' do
    def create_sequence(parent_type, parent_id)
      post :create, params: sequence_params.merge(parent_type: parent_type, parent_id: parent_id)
    end

    it 'creates gene sequence asset on a task step' do
      expect { create_sequence('Step', step.id) }.to change { step.assets.count }.by(1)
      expect(response).to have_http_status(:ok)
      asset = step.assets.last
      expect(asset.file.metadata['asset_type']).to eq 'gene_sequence'
      expect(asset.file.metadata['name']).to eq 'pUC19'
      expect(asset.file.filename.to_s).to eq 'pUC19.json'
      expect(JSON.parse(asset.file.download)).to eq('sequence' => 'ATGC', 'circular' => 'true')
      expect(asset.preview_image).to be_attached
      expect(asset.last_modified_by).to eq user
      expect(Activity.last.type_of).to eq 'task_sequence_asset_added'
    end

    it 'creates gene sequence asset on a result' do
      result = result_asset.result
      expect { create_sequence('Result', result.id) }.to change { result.assets.count }.by(1)
      expect(Activity.last.type_of).to eq 'sequence_on_result_added'
    end

    it 'creates gene sequence asset on a result template' do
      expect { create_sequence('ResultTemplate', result_template.id) }
        .to change { result_template.assets.count }.by(1)
      expect(Activity.last.type_of).to eq 'sequence_on_result_template_added'
    end

    it 'is forbidden when open vector editor is disabled' do
      allow(OpenVectorEditorService).to receive(:enabled?).and_return(false)
      expect { create_sequence('Step', step.id) }.not_to change(Asset, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden for viewers' do
      step
      downgrade_to_viewer(my_module)
      expect { create_sequence('Step', step.id) }.not_to change(Asset, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT #update' do
    def update_sequence(asset)
      put :update, params: sequence_params.merge(id: asset.id, sequence_name: 'pBR322')
    end

    it 'stores new version and logs activity for task step' do
      asset = step_asset.asset
      update_sequence(asset)
      expect(response).to have_http_status(:ok)
      asset.reload
      expect(asset.file.filename.to_s).to eq 'pBR322.json'
      expect(asset.file.metadata['asset_type']).to eq 'gene_sequence'
      expect(Activity.last.type_of).to eq 'task_sequence_asset_edit_finished'
    end

    it 'logs activity for result' do
      update_sequence(result_asset.asset)
      expect(Activity.last.type_of).to eq 'sequence_on_result_edited'
    end

    it 'logs activity for result template' do
      update_sequence(result_template_asset.asset)
      expect(Activity.last.type_of).to eq 'sequence_on_result_template_edited'
    end

    it 'is forbidden for viewers' do
      step_asset
      downgrade_to_viewer(my_module)
      update_sequence(step_asset.asset)
      expect(response).to have_http_status(:forbidden)
      expect(step_asset.asset.reload.file.filename.to_s).to eq 'test.jpg'
    end
  end
end
