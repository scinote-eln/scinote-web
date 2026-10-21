# frozen_string_literal: true

require 'rails_helper'

describe AtWhoController, type: :controller do
  render_views
  login_user

  include_context 'reference_project_structure', {
    team_role: :owner,
    step: true
  }

  let!(:pdf_asset) do
    create(:step_asset, step: step).asset.tap do |asset|
      # Update the blob's content_type directly (skipping callbacks) to avoid triggering the
      # real PDF text-extraction/preview pipeline against a non-PDF fixture file.
      asset.file.blob.update_columns(content_type: 'application/pdf')
    end
  end

  let!(:image_asset) { create(:step_asset, step: step).asset }
  let!(:titled_asset) do
    create(:step_asset, step: step).asset.tap { |asset| asset.update!(file_title: 'My file title') }
  end

  describe 'GET #search' do
    it 'flags pdf files and exposes the display name in a sa-task-files drill-down search' do
      get :search, params: { id: team.id, parent_type: 'sa-task-files', parent_id: my_module.id }, format: :json

      items = response.parsed_body['items']
      expect(items.find { |i| i['id'] == pdf_asset.id }['pdf']).to eq(true)
      expect(items.find { |i| i['id'] == image_asset.id }['pdf']).to eq(false)
      expect(items.find { |i| i['id'] == titled_asset.id }['display_name']).to eq('My file title')
      expect(items.find { |i| i['id'] == image_asset.id }['display_name']).to eq(image_asset.file_name)
    end

    it 'flags pdf files and exposes the display name in the cross-type global search' do
      get :search, params: { id: team.id }, format: :json

      items = response.parsed_body['items']
      expect(items.find { |i| i['id'] == pdf_asset.id }['pdf']).to eq(true)
      expect(items.find { |i| i['id'] == image_asset.id }['pdf']).to eq(false)
      expect(items.find { |i| i['id'] == titled_asset.id }['display_name']).to eq('My file title')
    end
  end
end
