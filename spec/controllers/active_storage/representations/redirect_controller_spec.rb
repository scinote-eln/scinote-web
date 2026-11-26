# frozen_string_literal: true

require 'rails_helper'
require 'vips'

describe ActiveStorage::Representations::RedirectController, type: :controller do
  login_user

  include_context 'reference_project_structure', { step: true }

  let(:image_path) { Rails.root.join('spec/fixtures/files/test.jpg') }
  let(:variation_key) { ActiveStorage::Variation.encode(resize_to_limit: [64, 64]) }
  let(:step_asset_record) { create(:step_asset, step: step).asset }

  def image_blob
    ActiveStorage::Blob.create_and_upload!(io: File.open(image_path), filename: 'test.jpg', content_type: 'image/jpeg',
                                           metadata: { identified: true, analyzed: true })
  end

  def pdf_blob
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new('%PDF-1.4 fake'), filename: 'doc.pdf',
                                           content_type: 'application/pdf',
                                           metadata: { identified: true, analyzed: true })
  end

  def attach_to_step_asset(blob)
    step_asset_record.file.attach(blob)
    blob
  end

  # Pretend the image is too large to be resized inline.
  def make_large!(blob)
    blob.update_column(:byte_size, Constants::INLINE_PREVIEW_MAX_FILE_SIZE + 1)
  end

  def request_representation(blob)
    get :show, params: { signed_blob_id: blob.signed_id, variation_key: variation_key, filename: blob.filename.to_s }
  end

  before do
    user.update!(current_team_id: team.id)
    allow(ActiveStorage::PreviewJob).to receive(:perform_later)
  end

  describe 'GET #show' do
    it 'redirects to the processed variant of a small inline image' do
      blob = attach_to_step_asset(image_blob)

      request_representation(blob)

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('/rails/active_storage/disk/')
      expect(blob.reload.variant_records.count).to eq 1
      expect(ActiveStorage::PreviewJob).not_to have_received(:perform_later)
    end

    it 'redirects for a TinyMCE image without checking the preview state' do
      tiny_mce_asset = TinyMceAsset.create!(team: team)
      blob = image_blob
      tiny_mce_asset.image.attach(blob)
      make_large!(blob)

      request_representation(blob)

      expect(response).to have_http_status(:redirect)
      expect(ActiveStorage::PreviewJob).not_to have_received(:perform_later)
    end

    it 'returns unprocessable entity when a previous preview failed' do
      blob = attach_to_step_asset(image_blob)
      blob.update!(metadata: blob.metadata.merge('preview_failed' => true))

      request_representation(blob)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns 404 json when the blob no longer exists' do
      blob = image_blob
      signed_id = blob.signed_id
      ActiveStorage::Blob.where(id: blob.id).delete_all

      get :show, params: { signed_blob_id: signed_id, variation_key: variation_key, filename: 'test.jpg' }

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({})
    end

    it 'is forbidden for a file the user cannot read' do
      blob = image_blob
      create(:asset, team: team).file.attach(blob)

      request_representation(blob)

      expect(response).to have_http_status(:forbidden)
    end

    context 'with a large image' do
      it 'schedules the preview and marks the asset as processing when no variant exists' do
        blob = attach_to_step_asset(image_blob)
        make_large!(blob)

        request_representation(blob)

        expect(response).to have_http_status(:accepted)
        expect(ActiveStorage::PreviewJob).to have_received(:perform_later).with(blob.id)
        expect(step_asset_record.reload.file_processing).to be true
      end

      it 'does not schedule another preview while the asset is processing' do
        blob = attach_to_step_asset(image_blob)
        make_large!(blob)
        step_asset_record.update_column(:file_processing, true)

        request_representation(blob)

        expect(response).to have_http_status(:accepted)
        expect(ActiveStorage::PreviewJob).not_to have_received(:perform_later)
      end

      it 'redirects when the variant has already been generated' do
        blob = attach_to_step_asset(image_blob)
        blob.representation(ActiveStorage::Variation.decode(variation_key)).processed
        make_large!(blob)

        request_representation(blob)

        expect(response).to have_http_status(:redirect)
        expect(ActiveStorage::PreviewJob).not_to have_received(:perform_later)
      end
    end

    context 'with a previewable non-image file' do
      it 'schedules the preview when no preview image exists' do
        blob = attach_to_step_asset(pdf_blob)

        request_representation(blob)

        expect(response).to have_http_status(:accepted)
        expect(ActiveStorage::PreviewJob).to have_received(:perform_later).with(blob.id)
        expect(step_asset_record.reload.file_processing).to be true
      end
    end

    context 'when image processing fails' do
      it 'flags the blob as failed and returns unprocessable entity' do
        tiny_mce_asset = TinyMceAsset.create!(team: team)
        blob = image_blob
        tiny_mce_asset.image.attach(blob)
        allow_any_instance_of(ActiveStorage::Blob).to receive(:representation).and_raise(Vips::Error, 'broken image')

        request_representation(blob)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(blob.reload.metadata['preview_failed']).to be true
      end
    end
  end
end
