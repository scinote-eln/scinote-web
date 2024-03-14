# frozen_string_literal: true

require 'rails_helper'

describe ReportsController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let(:my_module2) { create :my_module, experiment: experiment, created_by: experiment.created_by }
  let(:report) do
    create :report, user: user, project: project, team: team,
                    name: 'test repot A1', description: 'test description A1'
  end

  before(:all) do
    MyModuleStatusFlow.ensure_default
  end

  describe 'POST create' do
    context 'in JSON format' do
      let(:action) { post :create, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          report: { name: 'test report created',
                    description: 'test description created',
                    settings: Report::DEFAULT_SETTINGS },
          project_content: { experiments: [{ id: experiment.id, my_module_ids: [my_module.id] }] },
          template_values: [] }
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .once.with(hash_including(activity_type: :create_report)).ordered
        expect(Activities::CreateActivityService).to receive(:call)
          .once.with(hash_including(activity_type: :generate_pdf_report)).ordered
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  # Temporary disabled due to webpack problems
  end if false

  describe 'PUT update' do
    context 'in JSON format' do
      let(:action) { put :update, params: params, format: :json }
      let(:params) do
        { project_id: project.id,
          id: report.id,
          report: { name: 'test report update',
                    description: 'test description update' },
          project_content: { experiments: [{ id: experiment.id, my_module_ids: [my_module2.id] }] },
          template_values: [] }
      end
      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .once.with(hash_including(activity_type: :edit_report)).ordered
        expect(Activities::CreateActivityService).to receive(:call)
          .once.with(hash_including(activity_type: :generate_pdf_report)).ordered
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  # Temporary disabled due to webpack problems
  end if false

  describe 'DELETE destroy' do
    let(:action) { delete :destroy, params: params }
    let(:params) { { report_ids: [report.id] } }

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
