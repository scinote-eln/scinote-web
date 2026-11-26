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


  let(:protocol_in_repository) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:step_in_repository) { create :step, protocol: protocol_in_repository, user: user }

  let!(:asset) { create :asset }
  let(:step_asset) { create :step_asset, step: step, asset: asset }
  let(:step_asset_in_repository) { create :step_asset, step: step_in_repository, asset: asset }
  let(:result_asset) { create :result_asset, result: result, asset: asset }
  let(:token) { Token.create(token: 'token', ttl: Time.now.utc.to_i + Constants::WOPI_TOKEN_VALIDITY, user_id: user.id) }

  describe 'POST unlock' do
    before do
      token
      ENV['WOPI_SUBDOMAIN'] = nil
      allow(controller).to receive(:verify_proof!).and_return(true)
      @request.headers['X-WOPI-Override'] = 'UNLOCK'
      @request.headers['X-WOPI-Lock'] = 'lock'
      asset.wopi_lock_asset('lock')
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
  describe 'WOPI endpoints' do
    let(:result_template) do
      create :result_template, protocol: protocol_in_repository, user: user
    end
    let(:result_template_asset) { create :result_asset, result: result_template, asset: asset }

    before do
      token
      ENV['WOPI_SUBDOMAIN'] = nil
      allow(controller).to receive(:verify_proof!).and_return(true)
    end

    def wopi_post(override, headers = {})
      @request.headers['X-WOPI-Override'] = override
      headers.each { |k, v| @request.headers[k] = v }
      post :post_file_endpoint, params: { id: asset.id, access_token: 'token' }
    end

    def downgrade_to_viewer(assignable)
      UserAssignment.where(user: user, assignable: assignable)
                    .update_all(user_role_id: viewer_role.id)
    end

    describe 'authentication' do
      before { step_asset }

      it 'returns not found for unknown asset' do
        get :file_get_endpoint, params: { id: -1, access_token: 'token' }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns unauthorized without token' do
        get :file_get_endpoint, params: { id: asset.id }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns unauthorized with invalid token' do
        get :file_get_endpoint, params: { id: asset.id, access_token: 'wrong' }
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns not found when user cannot read asset' do
        UserAssignment.where(user: user, assignable: my_module).destroy_all
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'GET #file_get_endpoint (CheckFileInfo)' do
      it 'returns file info for task step asset' do
        step_asset
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        body = response.parsed_body
        expect(response).to have_http_status(:ok)
        expect(body['BaseFileName']).to eq 'test.jpg'
        expect(body['UserId']).to eq user.id.to_s
        expect(body['UserCanWrite']).to be true
        expect(body['BreadcrumbBrandName']).to eq project.name
        expect(body['BreadcrumbFolderName']).to eq my_module.name
        expect(body['Size']).to eq asset.file_size
        expect(response.headers['X-WOPI-ServerVersion']).to eq Scinote::Application::VERSION
      end

      it 'returns file info for protocol template step asset' do
        step_asset_in_repository
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        body = response.parsed_body
        expect(body['BreadcrumbBrandName']).to eq protocol_in_repository.name
        expect(body['BreadcrumbFolderName']).to eq 'Protocol managament'
      end

      it 'returns file info for result asset' do
        result_asset
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        body = response.parsed_body
        expect(body['BreadcrumbBrandName']).to eq project.name
        expect(body['BreadcrumbFolderName']).to eq my_module.name
        expect(body['CloseUrl']).to include("/modules/#{my_module.id}/results")
      end

      it 'returns file info for result template asset' do
        result_template_asset
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        body = response.parsed_body
        expect(body['BreadcrumbBrandName']).to eq protocol_in_repository.name
        expect(body['BreadcrumbFolderName']).to eq 'Protocol management'
      end

      it 'reports read only access for viewers' do
        step_asset
        downgrade_to_viewer(my_module)
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        expect(response.parsed_body['UserCanWrite']).to be false
      end
    end

    describe 'GET #file_contents_get_endpoint' do
      before { step_asset }

      it 'returns file contents' do
        get :file_contents_get_endpoint, params: { id: asset.id, access_token: 'token' }
        expect(response).to have_http_status(:ok)
        expect(response.body.bytesize).to eq asset.file_size
        expect(response.headers['X-WOPI-ItemVersion']).to eq asset.version
      end

      it 'returns empty body for new blank file' do
        asset.update_column(:version, 0)
        allow_any_instance_of(Asset).to receive(:file_size).and_return(0)
        get :file_contents_get_endpoint, params: { id: asset.id, access_token: 'token' }
        expect(response.body).to eq ''
      end
    end

    describe 'POST #post_file_endpoint' do
      before { step_asset }

      context 'with GET_LOCK' do
        it 'returns the current lock' do
          asset.wopi_lock_asset('abc')
          wopi_post('GET_LOCK')
          expect(response).to have_http_status(:ok)
          expect(response.headers['X-WOPI-Lock']).to eq 'abc'
        end

        it 'returns blank lock for unlocked file' do
          wopi_post('GET_LOCK')
          expect(response.headers['X-WOPI-Lock']).to eq ' '
        end
      end

      context 'with LOCK' do
        it 'locks unlocked file' do
          wopi_post('LOCK', 'X-WOPI-Lock' => 'abc')
          expect(response).to have_http_status(:ok)
          expect(asset.reload.wopi_lock).to eq 'abc'
        end

        it 'returns not found without lock header' do
          wopi_post('LOCK')
          expect(response).to have_http_status(:not_found)
        end

        it 'refreshes lock when same lock is used' do
          asset.wopi_lock_asset('abc')
          asset.update_column(:wopi_lock_ttl, Time.now.to_i + 10)
          wopi_post('LOCK', 'X-WOPI-Lock' => 'abc')
          expect(response).to have_http_status(:ok)
          expect(asset.reload.wopi_lock_ttl).to be > Time.now.to_i + 10
        end

        it 'returns conflict when locked with different lock' do
          asset.wopi_lock_asset('other')
          wopi_post('LOCK', 'X-WOPI-Lock' => 'abc')
          expect(response).to have_http_status(:conflict)
          expect(response.headers['X-WOPI-Lock']).to eq 'other'
        end

        it 'returns unauthorized for users without write access' do
          downgrade_to_viewer(my_module)
          wopi_post('LOCK', 'X-WOPI-Lock' => 'abc')
          expect(response).to have_http_status(:unauthorized)
          expect(asset.reload.wopi_lock).to be_nil
        end
      end

      context 'with LOCK and old lock (unlock and relock)' do
        it 'replaces the lock when old lock matches' do
          asset.wopi_lock_asset('old')
          wopi_post('LOCK', 'X-WOPI-Lock' => 'new', 'X-WOPI-OldLock' => 'old')
          expect(response).to have_http_status(:ok)
          expect(asset.reload.wopi_lock).to eq 'new'
        end

        it 'returns conflict when old lock does not match' do
          asset.wopi_lock_asset('current')
          wopi_post('LOCK', 'X-WOPI-Lock' => 'new', 'X-WOPI-OldLock' => 'old')
          expect(response).to have_http_status(:conflict)
          expect(response.headers['X-WOPI-Lock']).to eq 'current'
        end

        it 'returns conflict when file is not locked' do
          wopi_post('LOCK', 'X-WOPI-Lock' => 'new', 'X-WOPI-OldLock' => 'old')
          expect(response).to have_http_status(:conflict)
          expect(response.headers['X-WOPI-Lock']).to eq ' '
        end

        it 'returns bad request when lock is blank' do
          wopi_post('LOCK', 'X-WOPI-Lock' => '', 'X-WOPI-OldLock' => 'old')
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'with UNLOCK' do
        it 'returns bad request without lock' do
          wopi_post('UNLOCK')
          expect(response).to have_http_status(:bad_request)
        end

        it 'returns conflict with wrong lock' do
          asset.wopi_lock_asset('current')
          wopi_post('UNLOCK', 'X-WOPI-Lock' => 'wrong')
          expect(response).to have_http_status(:conflict)
          expect(asset.reload.wopi_lock).to eq 'current'
        end

        it 'returns conflict when not locked' do
          wopi_post('UNLOCK', 'X-WOPI-Lock' => 'abc')
          expect(response).to have_http_status(:conflict)
        end
      end

      context 'with REFRESH_LOCK' do
        it 'refreshes lock' do
          asset.wopi_lock_asset('abc')
          asset.update_column(:wopi_lock_ttl, Time.now.to_i + 10)
          wopi_post('REFRESH_LOCK', 'X-WOPI-Lock' => 'abc')
          expect(response).to have_http_status(:ok)
          expect(asset.reload.wopi_lock_ttl).to be > Time.now.to_i + 10
        end

        it 'returns bad request without lock' do
          wopi_post('REFRESH_LOCK')
          expect(response).to have_http_status(:bad_request)
        end

        it 'returns conflict with wrong lock' do
          asset.wopi_lock_asset('current')
          wopi_post('REFRESH_LOCK', 'X-WOPI-Lock' => 'wrong')
          expect(response).to have_http_status(:conflict)
          expect(response.headers['X-WOPI-Lock']).to eq 'current'
        end

        it 'returns conflict when not locked' do
          wopi_post('REFRESH_LOCK', 'X-WOPI-Lock' => 'abc')
          expect(response).to have_http_status(:conflict)
        end
      end

      it 'returns not implemented for GET_SHARE_URL' do
        wopi_post('GET_SHARE_URL')
        expect(response).to have_http_status(:not_implemented)
      end

      it 'returns not found for unknown override' do
        wopi_post('SOMETHING')
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'POST #file_contents_post_endpoint (PutFile)' do
      before { step_asset }

      def put_file(lock = nil, content = 'new content')
        @request.headers['X-WOPI-Lock'] = lock if lock
        post :file_contents_post_endpoint, params: { id: asset.id, access_token: 'token' }, body: content
      end

      it 'replaces file contents when lock matches' do
        asset.wopi_lock_asset('abc')
        expect { put_file('abc') }.to change { asset.reload.version }.by(1)
        expect(response).to have_http_status(:ok)
        expect(asset.reload.file.download).to eq 'new content'
        expect(asset.last_modified_by_id).to eq user.id
      end

      it 'returns conflict when lock does not match' do
        asset.wopi_lock_asset('abc')
        put_file('wrong')
        expect(response).to have_http_status(:conflict)
        expect(response.headers['X-WOPI-Lock']).to eq 'abc'
      end

      it 'returns conflict when modifying unlocked non-empty file' do
        put_file
        expect(response).to have_http_status(:conflict)
        expect(response.headers['X-WOPI-Lock']).to eq ' '
      end

      it 'initializes empty unlocked file' do
        asset.file.attach(io: StringIO.new(''), filename: 'empty.docx')
        asset.update_column(:version, 0)
        put_file
        expect(response).to have_http_status(:ok)
        expect(asset.reload.version).to eq 1
        expect(asset.file.download).to eq 'new content'
      end

      it 'returns unauthorized for users without write access' do
        downgrade_to_viewer(my_module)
        put_file('abc')
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'proof verification' do
      before do
        step_asset
        allow(controller).to receive(:verify_proof!).and_call_original
      end

      let(:ticks) { (Time.now.to_i * WopiUtil::CLR_TICKS_PER_SECOND) + WopiUtil::UNIX_EPOCH_IN_CLR_TICKS }

      it 'passes when proof is valid' do
        allow(controller).to receive(:wopi_verify_proof).and_return(true)
        @request.headers['X-WOPI-TimeStamp'] = ticks.to_s
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        expect(response).to have_http_status(:ok)
      end

      it 'fails when proof is invalid' do
        allow(controller).to receive(:wopi_verify_proof).and_return(false)
        @request.headers['X-WOPI-TimeStamp'] = ticks.to_s
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'fails when timestamp is too old' do
        old_ticks = ((Time.now - 1.hour).to_i * WopiUtil::CLR_TICKS_PER_SECOND) + WopiUtil::UNIX_EPOCH_IN_CLR_TICKS
        @request.headers['X-WOPI-TimeStamp'] = old_ticks.to_s
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'fails when verification raises' do
        @request.headers['X-WOPI-TimeStamp'] = ticks.to_s
        allow(controller).to receive(:wopi_verify_proof).and_raise(StandardError, 'boom')
        get :file_get_endpoint, params: { id: asset.id, access_token: 'token' }
        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
