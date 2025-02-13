# frozen_string_literal: true

require 'rails_helper'

describe TeamsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }

  describe 'POST export_projects' do
    before do
      view_response = '<div class="content-pane" id="report-new"><div class="report-container"><div id="report-content"></div></div></div>'
      proxy_manager = Warden::Manager.new({})
      proxy = Warden::Proxy.new({}, proxy_manager)
      renderer_double = double('Renderer', render: view_response.dup)

      allow(Warden::Manager).to receive(:new).and_return(proxy_manager)
      allow(Warden::Proxy).to receive(:new).with({}, proxy_manager).and_return(proxy)
      allow(ApplicationController.renderer).to receive(:new).with({ warden: proxy }).and_return(renderer_double)
      allow(ApplicationController).to receive(:render)
    end
  
    let!(:first_project) { create :project, team: team, created_by: user }
    let!(:second_project) { create :project, team: team, created_by: user }
    let(:params) do
      {
        id: team.id,
        project_ids: [first_project.id, second_project.id]
      }
    end
    let(:action) { post :export_projects, params: params, format: :json }

    it 'calls create activity for inviting user' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :export_projects)))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
