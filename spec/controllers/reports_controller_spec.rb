# frozen_string_literal: true

require 'rails_helper'

describe ReportsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:user_team) { create :user_team, team: team, user: user }
  let(:user_project) { create :user_project, :owner, user: user }
  let(:project) do
    create :project, team: team, user_projects: [user_project]
  end
  let(:report) do
    create :report, user: user, project: project, team: team,
                    name: 'test repot A1', description: 'test description A1'
  end

  describe 'POST create' do
    context 'in JSON format' do
      let(:action) { post :create, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          report: { name: 'test report created',
                    description: 'test description created' },
          report_contents: '[{"type_of":"project_header","id":{"project_id":' +
            project.id.to_s + '},"sort_order":null,"children":[]}]' }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :create_report))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'PUT update' do
    context 'in JSON format' do
      let(:action) { put :update, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          id: report.id,
          report: { name: 'test report update',
                    description: 'test description update' },
          report_contents: '[{"type_of":"project_header","id":{"project_id":' +
            project.id.to_s + '},"sort_order":null,"children":[]}]' }
      end
      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :edit_report))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params }
    let(:params) { { report_ids: "[#{report.id}]" } }

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :delete_report))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end
end
