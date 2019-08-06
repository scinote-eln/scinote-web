# frozen_string_literal: true

require 'rails_helper'

describe WopiController, type: :controller do
  ENV['WOPI_USER_HOST'] = 'localhost'

  login_user
  let(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let(:user_team) { create :user_team, :admin, user: user, team: team }
  let!(:user_project) { create :user_project, :owner, user: user }
  let(:project) do
    create :project, team: team, user_projects: [user_project]
  end
  let(:experiment) { create :experiment, project: project }
  let(:my_module) { create :my_module, name: 'test task', experiment: experiment }
  let(:result) do
    create :result, name: 'test result', my_module: my_module, user: user
  end
  let(:protocol) do
    create :protocol, my_module: my_module, team: team, added_by: user
  end
  let(:step) { create :step, protocol: protocol, user: user }

  let(:protocol_in_repository) { create :protocol, :in_public_repository, team: team }
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
        user_team
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
