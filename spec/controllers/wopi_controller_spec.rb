# frozen_string_literal: true

require 'rails_helper'

describe WopiController, type: :controller do
  ENV['WOPI_USER_HOST'] = 'localhost'

  login_user

  include_context 'reference_project_structure', {
    step: true
  }


  let(:result) do
    create :result, name: 'test result', my_module: my_module, user: user
  end


  let(:protocol_in_repository) { create :protocol, :in_public_repository, team: team, added_by: user }
  let(:step_in_repository) { create :step, protocol: protocol_in_repository, user: user }

  let!(:asset) { create :asset }
  let(:step_asset) { create :step_asset, step: step, asset: asset }
  let(:step_asset_in_repository) { create :step_asset, step: step_in_repository, asset: asset }
  let(:result_asset) { create :result_asset, result: result, asset: asset }
  let(:token) { Token.create(token: 'token', ttl: 0, user_id: user.id) }

  describe 'POST unlock' do
    before do
      token
      ENV['WOPI_SUBDOMAIN'] = nil
      allow(controller).to receive(:verify_proof!).and_return(true)
      @request.headers['X-WOPI-Override'] = 'UNLOCK'
      @request.headers['X-WOPI-Lock'] = 'lock'
      asset.lock_asset('lock')
    end

    let(:action) { post :post_file_endpoint, params: { id: asset.id, access_token: 'token' } }

    describe 'Result asset' do
      before do
        result_asset
      end

      it 'calls create activity for finish wopi editing' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                  .with(hash_including(activity_type:
                                         :edit_wopi_file_on_result)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    describe 'Step asset' do
      before do
        step_asset
      end

      it 'calls create activity for finish wopi editing' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                  .with(hash_including(activity_type:
                                         :edit_wopi_file_on_step)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    describe 'Step asset in repository' do
      before do
        step_asset_in_repository
      end

      it 'calls create activity for finish wopi editing' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                  .with(hash_including(activity_type:
                                         :edit_wopi_file_on_step_in_repository)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end
end
