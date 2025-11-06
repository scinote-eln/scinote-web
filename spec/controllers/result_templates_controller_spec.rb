# frozen_string_literal: true

require 'rails_helper'

describe ResultTemplatesController, type: :controller do
  include FileHelpers
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:result_template) { create :result_template, protocol: protocol, user: user }

  describe 'POST create' do
    it 'creates a new result template' do
      expect {
        post :create, params: { protocol_id: protocol.id }
      }.to change(ResultTemplate, :count).by(1)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'PUT update' do
    it 'updates an existing result template' do
      put :update, params: { protocol_id: result_template.protocol.id,
                             id: result_template.id,
                             result: { name: 'Updated Name' } }

      expect(response).to have_http_status(:success)
      result_template.reload
      expect(result_template.name).to eq('Updated Name')
    end
  end

  describe 'POST duplicate' do
    it 'duplicates an existing result template' do
      expect {
        post :duplicate, params: { protocol_id: result_template.protocol.id,
                                  id: result_template.id }
      }.to change(ResultTemplate, :count).by(1)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST update_view_state' do
    it 'updates the view state of an existing result template' do
      post :update_view_state, params: { protocol_id: result_template.protocol.id,
                                       id: result_template.id,
                                       assets: { order: 'atoz' } }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST update_asset_view_mode' do
    it 'updates the asset view mode of an existing result template' do
      post :update_asset_view_mode, params: { protocol_id: result_template.protocol.id,
                                            id: result_template.id,
                                            assets_view_mode: 'list' }
      expect(response).to have_http_status(:success)
      result_template.reload
      expect(result_template.assets_view_mode).to eq('list')
    end
  end

  describe 'POST upload_attachment' do
    it 'uploads an attachment to an existing result template' do
      signed_blob_id = create_signed_blob_id(filename: 'test.txt', content_type: 'text/plain', content: 'Hello, world!')
      post :upload_attachment, params: { protocol_id: result_template.protocol.id,
                                       id: result_template.id,
                                       signed_blob_id: signed_blob_id }
      expect(response).to have_http_status(:success)
      result_template.reload
      expect(result_template.assets.count).to eq(1)
    end
  end

  describe 'DELETE destroy' do
    it 'deletes an existing result template' do
      expect {
        delete :destroy, params: { protocol_id: result_template.protocol.id,
                                   id: result_template.id }
      }.to change(ResultTemplate, :count).by(-1)
      expect(response).to have_http_status(:success)
    end
  end
end
