# frozen_string_literal: true

require 'rails_helper'

describe TinyMceAssetsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { step: true }

  let(:image_path) { Rails.root.join('spec/fixtures/files/test.jpg') }
  let(:base64_image) { "data:image/jpeg;base64,#{Base64.strict_encode64(File.binread(image_path))}" }
  let(:json) { JSON.parse(response.body) }
  let(:token) { Base62.encode(tiny_mce_asset.id) }

  # A task in a team the current user is not a member of.
  let(:foreign_my_module) { create :my_module }
  let(:foreign_step) { create :step, protocol: foreign_my_module.protocol }

  def create_marvin_asset(object: nil, name: 'Benzene', description: 'Aromatic ring')
    asset = TinyMceAsset.create!(team: team, object: object)
    asset.image.attach(io: File.open(image_path), filename: 'sketch.jpg', content_type: 'image/jpeg',
                       metadata: { name: name, description: description, asset_type: 'marvinjs' })
    asset
  end

  def downgrade_to_viewer!
    UserAssignment.where(user: user).update_all(user_role_id: viewer_role.id)
  end

  before do
    user.update!(current_team_id: team.id)
  end

  describe 'POST #create' do
    # TinyMceAsset#self_destruct schedules deletion of unsaved images a day later; with
    # Delayed::Worker.delay_jobs = false (spec default) it would run immediately, unlike production.
    around do |example|
      delay_jobs = Delayed::Worker.delay_jobs
      Delayed::Worker.delay_jobs = true
      example.run
    ensure
      Delayed::Worker.delay_jobs = delay_jobs
    end

    it 'creates an unsaved image from an uploaded file and returns its url and token' do
      file = fixture_file_upload(image_path, 'image/jpeg')

      expect { post :create, params: { files: [file] }, format: :json }.to change(TinyMceAsset, :count).by(1)

      asset = TinyMceAsset.order(:id).last
      expect(response).to have_http_status(:ok)
      expect(asset.team).to eq team
      expect(asset.saved).to be false
      expect(asset.image).to be_attached
      expect(asset.image.filename.to_s).to eq 'test.jpg'
      expect(json['images'].size).to eq 1
      expect(json['images'].first['token']).to eq Base62.encode(asset.id)
      expect(json['images'].first['url']).to include("/rails/active_storage/blobs/redirect/#{asset.image.blob.signed_id}")
    end

    it 'creates an image from a signed blob id' do
      blob = ActiveStorage::Blob.create_and_upload!(io: File.open(image_path), filename: 'pasted.jpg',
                                                    content_type: 'image/jpeg')

      expect do
        post :create, params: { files: [{ blob_id: blob.signed_id }] }, format: :json
      end.to change(TinyMceAsset, :count).by(1)

      asset = TinyMceAsset.order(:id).last
      expect(response).to have_http_status(:ok)
      expect(asset.image.blob).to eq blob
      expect(json['images'].first['token']).to eq Base62.encode(asset.id)
    end

    it 'does not create an image with an unsupported content type' do
      file = fixture_file_upload(Rails.root.join('spec/fixtures/files/export.csv'), 'text/csv')

      expect { post :create, params: { files: [file] }, format: :json }.not_to change(TinyMceAsset, :count)
      expect(json['images']).to eq []
    end

    it 'reports the unsupported content type to the client' do
      pending 'bug: create_from_file builds an error message but rolls back silently, response is 200 with no images'
      file = fixture_file_upload(Rails.root.join('spec/fixtures/files/export.csv'), 'text/csv')

      post :create, params: { files: [file] }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to eq I18n.t('tiny_mce.unsupported_image_format')
    end

    context 'when the file is larger than the allowed size' do
      around do |example|
        max_size = Rails.configuration.x.file_max_size_mb
        Rails.configuration.x.file_max_size_mb = 0
        example.run
      ensure
        Rails.configuration.x.file_max_size_mb = max_size
      end

      it 'does not create an image' do
        file = fixture_file_upload(image_path, 'image/jpeg')

        expect { post :create, params: { files: [file] }, format: :json }.not_to change(TinyMceAsset, :count)
        expect(json['images']).to eq []
      end
    end

    it 'returns unprocessable entity when the image record is invalid' do
      invalid_asset = TinyMceAsset.new
      invalid_asset.errors.add(:estimated_size, :blank)
      allow_any_instance_of(TinyMceAsset).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(invalid_asset))
      file = fixture_file_upload(image_path, 'image/jpeg')

      post :create, params: { files: [file] }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to start_with('Validation failed')
      expect(json).not_to have_key('images')
    end
  end

  describe 'GET #download' do
    it 'redirects to the attachment of an unassigned image of the current team' do
      tiny_mce_asset = create :tiny_mce_asset, team: team

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to redirect_to(%r{/rails/active_storage/blobs/redirect/.+test\.jpg\?disposition=attachment})
    end

    it 'redirects for an image in a task the user can read' do
      tiny_mce_asset = create :tiny_mce_asset, team: team, object: my_module

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:redirect)
    end

    it 'redirects for an image in a result text the user can read' do
      result_text = create :result_text, result: create(:result, my_module: my_module, user: user)
      tiny_mce_asset = create :tiny_mce_asset, team: team, object: result_text

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:redirect)
    end

    it 'redirects for an image in a step text the user can read' do
      tiny_mce_asset = create :tiny_mce_asset, team: team, object: create(:step_text, step: step)

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:redirect)
    end

    it 'redirects for an image in a protocol the user can read' do
      tiny_mce_asset = create :tiny_mce_asset, team: team, object: my_module.protocol

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:redirect)
    end

    it 'returns 404 when the image has no attachment' do
      tiny_mce_asset = TinyMceAsset.create!(team: team)

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an image of another team' do
      tiny_mce_asset = create :tiny_mce_asset

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 for an image in a task the user cannot read' do
      tiny_mce_asset = create :tiny_mce_asset, team: team, object: foreign_my_module

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for an image in a step text the user cannot read' do
      tiny_mce_asset = create :tiny_mce_asset, team: team, object: create(:step_text, step: foreign_step)

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 for an image attached to an unsupported object' do
      tiny_mce_asset = create :tiny_mce_asset, team: team, object: step

      get :download, params: { id: Base62.encode(tiny_mce_asset.id) }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET #marvinjs_show' do
    it 'returns the sketch name and description' do
      tiny_mce_asset = create_marvin_asset(object: my_module)

      get :marvinjs_show, params: { id: Base62.encode(tiny_mce_asset.id) }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json).to eq('name' => 'Benzene', 'description' => 'Aromatic ring')
    end

    it 'logs a start editing activity when opened for editing' do
      tiny_mce_asset = create_marvin_asset(object: my_module)

      expect do
        get :marvinjs_show, params: { id: Base62.encode(tiny_mce_asset.id), show_action: 'start_edit' }, format: :json
      end.to change { Activity.where(type_of: :edit_chemical_structure_on_task, subject: my_module).count }.by(1)

      activity = Activity.where(type_of: :edit_chemical_structure_on_task, subject: my_module).order(:id).last
      expect(activity.owner).to eq user
      expect(activity.values['message_items']['action']).to eq I18n.t('activities.file_editing.started')
    end

    it 'returns 404 for an unknown sketch' do
      missing_id = TinyMceAsset.create!(team: team).tap(&:destroy!).id

      get :marvinjs_show, params: { id: Base62.encode(missing_id) }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 for a sketch in a protocol the user cannot read' do
      tiny_mce_asset = create_marvin_asset(object: foreign_my_module.protocol)

      get :marvinjs_show, params: { id: Base62.encode(tiny_mce_asset.id) }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #marvinjs_create' do
    let(:sketch_params) { { name: 'Ethanol', description: 'C2H6O', image: base64_image } }

    it 'creates a TinyMCE sketch and returns its preview url and token' do
      expect do
        post :marvinjs_create, params: sketch_params.merge(object_type: 'TinyMceAsset'), format: :json
      end.to change(TinyMceAsset, :count).by(1)

      asset = TinyMceAsset.order(:id).last
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq 'text/html'
      expect(asset.team).to eq team
      expect(asset.image.metadata[:name]).to eq 'Ethanol'
      expect(json['image']['token']).to eq Base62.encode(asset.id)
      expect(json['image']['source_type']).to eq 'marvinjs'
      expect(json['image']['url']).to include('/rails/active_storage/representations/redirect/')
    end

    it 'returns unprocessable entity when no sketch was created' do
      pending 'bug: else branch calls result[:asset].errors on nil and raises NoMethodError'
      allow(MarvinJsService).to receive(:create_sketch).and_return({ asset: nil })

      post :marvinjs_create, params: sketch_params.merge(object_type: 'TinyMceAsset'), format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'does not attach a sketch to a step the user cannot manage' do
      pending 'bug: marvinjs_create has no permission check; object_type Step attaches a sketch to any step by id (then 500s on Asset#preview)'
      foreign_step

      post :marvinjs_create, params: sketch_params.merge(object_type: 'Step', object_id: foreign_step.id),
                             format: :json

      expect(foreign_step.assets.count).to eq 0
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT #marvinjs_update' do
    let(:update_params) do
      { id: token, object_type: 'TinyMceAsset', name: 'Updated', description: 'New', image: base64_image }
    end

    context 'with an unassigned sketch' do
      let(:tiny_mce_asset) { create_marvin_asset }

      it 'replaces the image and returns the new preview url' do
        old_blob_id = tiny_mce_asset.image.blob.id

        put :marvinjs_update, params: update_params, format: :json

        tiny_mce_asset.reload
        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq tiny_mce_asset.id
        expect(json['url']).to include('/rails/active_storage/representations/redirect/')
        expect(tiny_mce_asset.image.blob.id).not_to eq old_blob_id
        expect(tiny_mce_asset.image.metadata[:name]).to eq 'Updated'
      end

      it 'returns unprocessable entity when the sketch could not be updated' do
        allow(MarvinJsService).to receive(:update_sketch).and_return(nil)

        put :marvinjs_update, params: update_params, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to eq I18n.t('marvinjs.no_sketches_found')
      end
    end

    context 'with a sketch in a task' do
      let(:tiny_mce_asset) { create_marvin_asset(object: my_module) }

      it 'updates the sketch and logs a finish editing activity' do
        expect do
          put :marvinjs_update, params: update_params, format: :json
        end.to change { Activity.where(type_of: :edit_chemical_structure_on_task, subject: my_module).count }.by(1)

        expect(response).to have_http_status(:ok)
        activity = Activity.where(type_of: :edit_chemical_structure_on_task, subject: my_module).order(:id).last
        expect(activity.values['message_items']['action']).to eq I18n.t('activities.file_editing.finished')
      end

      it 'is forbidden for a viewer' do
        downgrade_to_viewer!

        put :marvinjs_update, params: update_params, format: :json

        expect(response).to have_http_status(:forbidden)
        expect(tiny_mce_asset.reload.image.metadata[:name]).to eq 'Benzene'
      end
    end

    context 'with a sketch in a result text' do
      let(:result_text) { create :result_text, result: create(:result, my_module: my_module, user: user) }
      let(:tiny_mce_asset) { create_marvin_asset(object: result_text) }

      it 'updates the sketch' do
        put :marvinjs_update, params: update_params, format: :json

        expect(response).to have_http_status(:ok)
        expect(tiny_mce_asset.reload.image.metadata[:name]).to eq 'Updated'
      end
    end

    context 'with a sketch in a step text' do
      let(:tiny_mce_asset) { create_marvin_asset(object: create(:step_text, step: step)) }

      it 'updates the sketch' do
        put :marvinjs_update, params: update_params, format: :json

        expect(response).to have_http_status(:ok)
        expect(tiny_mce_asset.reload.image.metadata[:name]).to eq 'Updated'
      end

      it 'is forbidden for a viewer' do
        downgrade_to_viewer!

        put :marvinjs_update, params: update_params, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with a sketch in a protocol' do
      let(:tiny_mce_asset) { create_marvin_asset(object: my_module.protocol) }

      it 'updates the sketch' do
        put :marvinjs_update, params: update_params, format: :json

        expect(response).to have_http_status(:ok)
        expect(tiny_mce_asset.reload.image.metadata[:name]).to eq 'Updated'
      end

      it 'is forbidden for a viewer' do
        downgrade_to_viewer!

        put :marvinjs_update, params: update_params, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
