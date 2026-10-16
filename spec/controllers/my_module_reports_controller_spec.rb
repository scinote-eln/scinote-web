# frozen_string_literal: true

require 'rails_helper'

describe MyModuleReportsController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }

  let(:json) { JSON.parse(response.body) }
  let(:protocol) { my_module.protocol }
  let!(:report_template) { ReportTemplate.create!(name: 'Template A', subject: protocol) }
  let(:viewer) { create :user, confirmed_at: Time.zone.now }

  def create_report(name: 'Report', status: :done, template: report_template, attach: true, created_at: nil)
    report = AnalyticalReport.create!(name: name, generating_status: status, reference: my_module,
                                      created_by: user, report_template: template)
    report.report.attach(io: StringIO.new('%PDF-1.4 test'), filename: "#{name}.pdf",
                         content_type: 'application/pdf') if attach
    report.update_column(:created_at, created_at) if created_at
    report
  end

  # A viewer can read the task but never manage its reports.
  def become_viewer
    sign_out user
    viewer.update!(current_team_id: team.id)
    create_user_assignment(team, viewer_role, viewer, user)
    create_user_assignment(my_module, viewer_role, viewer, user)
    sign_in viewer
  end

  # A team member without any access to the task (no task assignment), so read permission is missing.
  def become_user_without_task_access
    outsider = create :user, confirmed_at: Time.zone.now
    outsider.update!(current_team_id: team.id)
    create_user_assignment(team, viewer_role, outsider, user)
    sign_out user
    sign_in outsider
  end

  before do
    user.update!(current_team_id: team.id)
    allow(ReportTemplate).to receive(:analytical_reporting_enabled?).and_return(true)
  end

  describe 'before actions' do
    it 'returns 403 when analytical reporting is disabled' do
      allow(ReportTemplate).to receive(:analytical_reporting_enabled?).and_return(false)
      get :index, params: { my_module_id: my_module.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 for an unknown task' do
      pending 'bug: load_my_module keeps running after render_404 and raises NoMethodError on nil'
      get :index, params: { my_module_id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'switches the current team to the team of the task' do
      other_team = create :team, created_by: user, skip_user_assignments: true
      user.update!(current_team_id: other_team.id)
      get :index, params: { my_module_id: my_module.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.current_team_id).to eq team.id
    end
  end

  describe 'GET index' do
    context 'with json views rendered' do
      render_views

      it 'lists only finished reports of the task, newest first' do
        create_report(name: 'Older', created_at: 2.days.ago)
        newer = create_report(name: 'Newer')
        create_report(name: 'Running', status: :in_progress, attach: false)
        get :index, params: { my_module_id: my_module.id }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json['reports'].map { |r| r['name'] }).to eq %w(Newer Older)
        expect(json['reports'].first).to include(
          'id' => newer.id,
          'preview' => preview_my_module_my_module_report_path(my_module, newer)
        )
      end
    end

    context 'with html format' do
      # templates are stubbed here: the page loads a webpack bundle that is not compiled in specs
      it 'renders the html page with navigator and inline name editing' do
        get :index, params: { my_module_id: my_module.id }
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq 'text/html'
        expect(assigns(:navigator)).to include(id: my_module.code,
                                               url: tree_navigator_my_module_path(my_module),
                                               archived: false)
        expect(assigns(:inline_editable_title_config)).to include(item_id: my_module.id,
                                                                  path_to_update: my_module_path(my_module))
      end
    end

    it 'does not offer inline name editing to a viewer' do
      become_viewer
      get :index, params: { my_module_id: my_module.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(assigns(:inline_editable_title_config)).to be_nil
    end
  end

  describe 'POST create' do
    let(:params) do
      { my_module_id: my_module.id, report_template_id: report_template.id, header: 'Head', footer: 'Foot',
        add_numarization: 'true', add_blank_page: 'false', asset_ids: %w(1 2) }
    end

    it 'creates an in-progress report and enqueues the generation job' do
      expect(MyModules::GenerateReportJob).to receive(:perform_later) do |id, opts|
        expect(id).to eq AnalyticalReport.last.id
        expect(opts).to eq(team_id: team.id)
      end

      expect { post :create, params: params, format: :json }.to change { my_module.analytical_reports.count }.by(1)

      report = my_module.analytical_reports.last
      expect(response).to have_http_status(:no_content).or have_http_status(:ok)
      expect(report).to have_attributes(name: 'Template A', generating_status: 'in_progress',
                                        created_by: user, report_template_id: report_template.id)
      expect(report.params).to include('header' => 'Head', 'footer' => 'Foot', 'asset_ids' => %w(1 2))
    end

    it 'returns 404 for a template of another protocol' do
      other = ReportTemplate.create!(name: 'Foreign', subject: create(:protocol, :in_repository_draft, team: team,
                                                                                                       added_by: user))
      expect(MyModules::GenerateReportJob).not_to receive(:perform_later)
      expect do
        post :create, params: params.merge(report_template_id: other.id), format: :json
      end.not_to(change { AnalyticalReport.count })
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for a viewer' do
      become_viewer
      expect(MyModules::GenerateReportJob).not_to receive(:perform_later)
      expect { post :create, params: params, format: :json }.not_to(change { AnalyticalReport.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET report_templates' do
    render_views

    it 'lists templates of the task protocol and flags those being generated' do
      busy = ReportTemplate.create!(name: 'Busy', subject: protocol)
      busy.update_column(:created_at, 1.day.from_now)
      create_report(name: 'Running', status: :in_progress, template: busy, attach: false)
      get :report_templates, params: { my_module_id: my_module.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['templates'].map { |t| [t['name'], t['generating_report']] }).to eq [['Busy', true],
                                                                                          ['Template A', false]]
      expect(json['templates'].last['preview']).to eq(
        preview_protocol_protocol_report_template_path(protocol, report_template)
      )
    end

    it 'is forbidden without read permission' do
      other_user = create :user, confirmed_at: Time.zone.now
      other_user.update!(current_team_id: team.id)
      create_user_assignment(team, viewer_role, other_user, user)
      sign_out user
      sign_in other_user
      get :report_templates, params: { my_module_id: my_module.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET pdfs' do
    render_views

    let(:step) { create :step, protocol: protocol, user: user, position: 0 }

    def attach_pdf(parent, filename)
      asset = create :asset
      asset.file.attach(io: StringIO.new('%PDF-1.4'), filename: filename, content_type: 'application/pdf')
      parent.is_a?(Step) ? StepAsset.create!(step: parent, asset: asset) : ResultAsset.create!(result: parent, asset: asset)
      asset
    end

    it 'lists pdf assets of steps first and then of results with their origin' do
      step_asset = attach_pdf(step, 'a_step.pdf')
      result = create :result, my_module: my_module, user: user, name: 'Res 1'
      result_asset = attach_pdf(result, 'b_result.pdf')
      get :pdfs, params: { my_module_id: my_module.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['data'].map { |a| a['id'] }).to eq [step_asset.id, result_asset.id]
      expect(json['data'].map { |a| a['parent_name'] }).to eq [
        I18n.t('my_modules.reports.wizard.first_step.asset_from_step', name: step.name),
        I18n.t('my_modules.reports.wizard.first_step.asset_from_result', name: 'Res 1')
      ]
      expect(json['data'].first['medium_preview']).to include('/rails/active_storage/representations/')
      expect(json['data'].first).to include('file_name' => 'a_step.pdf', 
                                            'preview' => asset_file_preview_path(step_asset))
    end

    it 'returns an empty list when there are no pdf assets' do
      get :pdfs, params: { my_module_id: my_module.id }, format: :json

      expect(json['data']).to eq []
    end
  end

  describe 'read permission checks' do
    let!(:analytical_report) { create_report }

    before { become_user_without_task_access }

    it 'is forbidden for pdfs' do
      get :pdfs, params: { my_module_id: my_module.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden for download' do
      get :download, params: { my_module_id: my_module.id, id: analytical_report.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden for preview' do
      get :preview, params: { my_module_id: my_module.id, id: analytical_report.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE destroy' do
    let!(:analytical_report) { create_report }

    it 'destroys the report and logs the activity' do
      expect(Activities::CreateActivityService).to receive(:call).with(
        hash_including(activity_type: :task_analytical_report_deleted, owner: user, subject: my_module,
                       message_items: { analytical_report: analytical_report.id, my_module: my_module.id })
      )
      expect { delete :destroy, params: { my_module_id: my_module.id, id: analytical_report.id }, format: :json }
        .to change { AnalyticalReport.count }.by(-1)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 and keeps the report when destroying fails' do
      allow(Activities::CreateActivityService).to receive(:call)
      allow_any_instance_of(AnalyticalReport).to receive(:destroy!)
        .and_raise(ActiveRecord::RecordInvalid.new(analytical_report))
      expect { delete :destroy, params: { my_module_id: my_module.id, id: analytical_report.id }, format: :json }
        .not_to(change { AnalyticalReport.count })
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to be_present
    end

    it 'returns 404 for a report of another task' do
      other_module = create :my_module, experiment: experiment, created_by: user
      foreign = AnalyticalReport.create!(name: 'F', generating_status: :done, reference: other_module)
      expect { delete :destroy, params: { my_module_id: my_module.id, id: foreign.id }, format: :json }
        .not_to(change { AnalyticalReport.count })
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for a viewer' do
      become_viewer
      expect { delete :destroy, params: { my_module_id: my_module.id, id: analytical_report.id }, format: :json }
        .not_to(change { AnalyticalReport.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET download' do
    let!(:analytical_report) { create_report }

    it 'redirects to the attached report as an attachment' do
      get :download, params: { my_module_id: my_module.id, id: analytical_report.id }

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include('disposition=attachment').or include('attachment')
      expect(response.location).to include("#{analytical_report.name}.pdf")
    end

    it 'returns 404 for an unknown report' do
      get :download, params: { my_module_id: my_module.id, id: -1 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET preview' do
    render_views

    let!(:analytical_report) { create_report(name: 'Preview me') }

    it 'returns the rendered preview html with the download link' do
      get :preview, params: { my_module_id: my_module.id, id: analytical_report.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['html']).to include('Preview me')
      expect(json['html']).to include(download_my_module_my_module_report_path(my_module.id, analytical_report))
    end

    it 'returns 404 for an unknown report' do
      get :preview, params: { my_module_id: my_module.id, id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
