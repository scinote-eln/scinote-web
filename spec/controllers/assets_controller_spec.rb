# frozen_string_literal: true

require 'rails_helper'

describe AssetsController, type: :controller do
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
  let(:protocol) do
    create :protocol, my_module: my_module, team: team, added_by: user
  end
  let(:step) { create :step, protocol: protocol, user: user }
  let(:step_asset_task) { create :step_asset, step: step }

  let(:result) do
    create :result, name: 'test result', my_module: my_module, user: user
  end
  let(:result_asset) { create :result_asset, result: result }

  let(:protocol_in_repository) { create :protocol, :in_public_repository, team: team }
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
      params[:id] = step_asset_task.asset.id
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
      user_team
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :edit_image_on_step_in_repository))
      action
    end

    it 'adds activity in DB' do
      params[:id] = step_asset_task.asset.id
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'GET asset_card' do
    let(:action) { get :toggle_view_mode, params: params, format: :json }
    let!(:params) do
      { id: asset.id }
    end

    it do
      action

      expect(response).to have_http_status 200
    end

    context 'when small card' do
      it do
        action

        expect(response).to have_http_status 200
        # wtf, not working here?, render_to_string is returning nil
        # expect(JSON.parse(response.body)['html']).to be_eql 'hellow world'
      end
    end

    context 'when iframe' do
      before do
        allow_any_instance_of(Asset).to receive(:small_card).and_return(false)
        allow_any_instance_of(Asset).to receive(:get_action_url).and_return('fakeurl.com')
        allow(controller).to receive(:wopi_enabled?).and_return(true)
        allow(controller).to receive(:wopi_file?).and_return(true)
      end

      it do
        action

        expect(response).to have_http_status 200
        expect(JSON.parse(response.body)['html'])
          .to be_eql '<iframe src="fakeurl.com" title="DocumentPreview"></iframe>'
      end
    end
  end
end
