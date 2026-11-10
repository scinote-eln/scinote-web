# frozen_string_literal: true

require 'rails_helper'

describe ActiveStorage::DirectUploadsController, type: :controller do
  let(:content) { 'direct upload content' }
  let(:blob_params) do
    {
      filename: 'notes.txt',
      byte_size: content.bytesize,
      checksum: Digest::MD5.base64digest(content),
      content_type: 'text/plain',
      metadata: { origin: 'spec' }
    }
  end
  let(:json) { JSON.parse(response.body) }

  context 'with a signed in user' do
    login_user

    describe 'POST #create' do
      it 'creates a blob and returns its signed id and upload instructions' do
        expect { post :create, params: { blob: blob_params }, as: :json }.to change(ActiveStorage::Blob, :count).by(1)

        blob = ActiveStorage::Blob.order(:id).last
        expect(response).to have_http_status(:ok)
        expect(blob.filename.to_s).to eq 'notes.txt'
        expect(blob.byte_size).to eq content.bytesize
        expect(blob.content_type).to eq 'text/plain'
        expect(blob.metadata['origin']).to eq 'spec'
        expect(json['signed_id']).to eq blob.signed_id
        expect(json['direct_upload']['url']).to include('/rails/active_storage/disk/')
        expect(json['direct_upload']['headers']).to eq('Content-Type' => 'text/plain')
      end

      it 'defaults a blank content type to application/octet-stream' do
        post :create, params: { blob: blob_params.merge(content_type: '') }, as: :json

        expect(response).to have_http_status(:ok)
        expect(ActiveStorage::Blob.order(:id).last.content_type).to eq 'application/octet-stream'
        expect(json['content_type']).to eq 'application/octet-stream'
      end

      it 'is forbidden for files larger than the configured maximum' do
        too_large = Rails.configuration.x.file_max_size_mb.megabytes + 1

        expect do
          post :create, params: { blob: blob_params.merge(byte_size: too_large) }, as: :json
        end.not_to change(ActiveStorage::Blob, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context 'with an API bearer token' do
    let(:user) { create(:user).tap(&:confirm) }

    it 'authenticates the request and creates the blob' do
      request.headers['Authorization'] = "Bearer #{Api::CoreJwt.encode(sub: user.id)}"

      expect { post :create, params: { blob: blob_params }, as: :json }.to change(ActiveStorage::Blob, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(controller.current_user).to eq user
    end
  end

  context 'without authentication' do
    it 'does not create a blob' do
      expect { post :create, params: { blob: blob_params }, as: :json }.not_to change(ActiveStorage::Blob, :count)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
