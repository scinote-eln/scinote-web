# frozen_string_literal: true

require 'rails_helper'

describe ExperimentReportsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }

  let(:json) { JSON.parse(response.body) }
  let(:viewer) { create :user, confirmed_at: Time.zone.now }

  def create_report(name: 'Report', status: :done, attach: true, created_at: nil, reference: experiment)
    report = AnalyticalReport.create!(name: name, generating_status: status, reference: reference, created_by: user)
    report.report.attach(io: StringIO.new('%PDF-1.4 test'), filename: "#{name}.pdf",
                         content_type: 'application/pdf') if attach
    report.update_column(:created_at, created_at) if created_at
    report
  end

  # A viewer can read the experiment but never manage it.
  def become_viewer
    sign_out user
    viewer.update!(current_team_id: team.id)
    create_user_assignment(team, viewer_role, viewer, user)
    create_user_assignment(experiment, viewer_role, viewer, user)
    sign_in viewer
  end

  before do
    user.update!(current_team_id: team.id)
    allow(AnalyticalReport).to receive(:experiment_reporting_enabled?).and_return(true)
  end

  describe 'before actions' do
    it 'returns 403 when experiment reporting is disabled' do
      allow(AnalyticalReport).to receive(:experiment_reporting_enabled?).and_return(false)
      get :index, params: { experiment_id: experiment.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 for an unknown experiment' do
      pending 'bug: load_experiment keeps running after render_404 and raises NoMethodError on nil'
      get :index, params: { experiment_id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'switches the current team to the team of the experiment' do
      pending 'bug: ExperimentReportsController does not include TeamsHelper, current_team_switch is undefined'
      other_team = create :team, created_by: user, skip_user_assignments: true
      user.update!(current_team_id: other_team.id)
      get :index, params: { experiment_id: experiment.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.current_team_id).to eq team.id
    end
  end

  describe 'GET index' do
    render_views

    it 'lists only finished reports of the experiment, newest first' do
      create_report(name: 'Older', created_at: 2.days.ago)
      newer = create_report(name: 'Newer')
      create_report(name: 'Running', status: :in_progress, attach: false)
      other_experiment = create :experiment, project: project, created_by: user
      create_report(name: 'Foreign', reference: other_experiment)
      get :index, params: { experiment_id: experiment.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['reports'].map { |r| r['name'] }).to eq %w(Newer Older)
      expect(json['reports'].first).to include(
        'id' => newer.id,
        'created_by' => user.full_name,
        'preview' => preview_experiment_experiment_report_path(experiment, newer),
        'file_size' => ActionController::Base.helpers.number_to_human_size(newer.report.byte_size)
      )
    end

    it 'is forbidden without read permission' do
      other_user = create :user, confirmed_at: Time.zone.now
      other_user.update!(current_team_id: team.id)
      create_user_assignment(team, viewer_role, other_user, user)
      sign_out user
      sign_in other_user
      get :index, params: { experiment_id: experiment.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create' do
    let(:params) { { experiment_id: experiment.id, name: 'Exp report', my_module_ids: [my_module.id] } }

    it 'creates an in-progress report and enqueues the generation job' do
      allow(Experiments::GenerateReportJob).to receive(:perform_later)

      expect { post :create, params: params, format: :json }.to change { experiment.analytical_reports.count }.by(1)

      report = experiment.analytical_reports.last
      expect(report).to have_attributes(name: 'Exp report', generating_status: 'in_progress', created_by: user)
      expect(report.params).to eq('my_module_ids' => [my_module.id.to_s])
      expect(Experiments::GenerateReportJob).to have_received(:perform_later).with(report.id)
    end

    it 'is forbidden for a viewer' do
      become_viewer
      expect(Experiments::GenerateReportJob).not_to receive(:perform_later)
      expect { post :create, params: params, format: :json }.not_to(change { AnalyticalReport.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE destroy' do
    let!(:analytical_report) { create_report }

    it 'destroys the report and logs the activity' do
      expect(Activities::CreateActivityService).to receive(:call).with(
        hash_including(activity_type: :experiment_analytical_report_deleted, owner: user, subject: experiment,
                       message_items: { analytical_report: analytical_report.id, experiment: experiment.id })
      )
      expect { delete :destroy, params: { experiment_id: experiment.id, id: analytical_report.id }, format: :json }
        .to change { AnalyticalReport.count }.by(-1)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 and keeps the report when destroying fails' do
      allow(Activities::CreateActivityService).to receive(:call)
      allow_any_instance_of(AnalyticalReport).to receive(:destroy!)
        .and_raise(ActiveRecord::RecordInvalid.new(analytical_report))
      expect { delete :destroy, params: { experiment_id: experiment.id, id: analytical_report.id }, format: :json }
        .not_to(change { AnalyticalReport.count })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to be_present
    end

    it 'returns 404 for an unknown report' do
      delete :destroy, params: { experiment_id: experiment.id, id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for a viewer' do
      become_viewer
      expect { delete :destroy, params: { experiment_id: experiment.id, id: analytical_report.id }, format: :json }
        .not_to(change { AnalyticalReport.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET download' do
    let!(:analytical_report) { create_report(name: 'Downloadable') }

    it 'redirects to the attached report as an attachment' do
      get :download, params: { experiment_id: experiment.id, id: analytical_report.id }

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('Downloadable.pdf')
    end

    it 'returns 404 for an unknown report' do
      get :download, params: { experiment_id: experiment.id, id: -1 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET preview' do
    include_context 'without compiled assets'
    render_views

    let!(:analytical_report) { create_report(name: 'Preview me') }

    it 'returns the rendered preview html with the download link' do
      get :preview, params: { experiment_id: experiment.id, id: analytical_report.id,
                              gallery: [analytical_report.id] }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['html']).to include('Preview me')
      expect(json['html']).to include(download_experiment_experiment_report_path(experiment.id, analytical_report))
    end

    it 'renders the preview without a gallery param' do
      pending 'bug: preview calls in_order_of(:id, params[:gallery]) which raises NoMethodError when gallery is missing'
      get :preview, params: { experiment_id: experiment.id, id: analytical_report.id }, format: :json

      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 for an unknown report' do
      get :preview, params: { experiment_id: experiment.id, id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET my_modules' do
    render_views

    it 'lists distinct active tasks of the experiment that have reports' do
      with_reports = my_module
      create_report(name: 'R1', reference: with_reports)
      create_report(name: 'R2', reference: with_reports)
      create :my_module, experiment: experiment, created_by: user, name: 'No reports'
      archived = create :my_module, experiment: experiment, created_by: user, archived: true
      create_report(name: 'R3', reference: archived)
      get :my_modules, params: { experiment_id: experiment.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['tasks']).to eq [{ 'id' => with_reports.id, 'name' => with_reports.name }]
    end

    it 'is forbidden for a viewer' do
      become_viewer
      get :my_modules, params: { experiment_id: experiment.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
