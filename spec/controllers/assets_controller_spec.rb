# frozen_string_literal: true

require 'rails_helper'

describe AssetsController, type: :controller do
  login_user

  include_context 'reference_project_structure', {
    team_role: :owner,
    result_asset: true,
    step: true,
    step_asset: true,
    result_comment: true
  }

  let(:protocol_in_repository) { create :protocol, :in_public_repository, team: team, added_by: user }
  let(:step_in_repository) { create :step, protocol: protocol_in_repository, user: user }

  let!(:asset) { create :asset }
  let(:step_asset_in_repository) { create :step_asset, step: step_in_repository, asset: asset }



  describe 'POST start_edit' do
    before do
      allow(controller).to receive(:check_edit_permission).and_return(true)
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
end
