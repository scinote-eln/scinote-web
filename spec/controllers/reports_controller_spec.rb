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

  before do
    MyModuleStatusFlow.ensure_default
  end

  describe 'GET index' do
    let(:action) { get :index, params: { page: 1, per_page: 20 }, format: :json }
    let!(:repository) { create :repository, team: team, created_by: user }
    it 'correct JSON format' do
      report
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(1)
      expect(parsed_response['data'].first['id']).to eq(report.id.to_s)
    end
  end

  describe 'GET new' do
    let(:action) { get :new }
    it 'correct new response' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'GET edit' do
    let(:action) { get :edit, params: { project_id: project.id, id: report.id } }
    it 'correct new response' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'GET #new_template_values' do
    let(:action) { get :new_template_values, params: request_params, format: 'json'}

    context 'when all params are provided' do
      let(:request_params) do
        {
          project_id: project.id,
          template: 'scinote_template',
          report_id: report.id
        }
      end

      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
      end
    end

    context 'when report_id is missing' do
      let(:request_params) do
        {
          project_id: project.id,
          template: 'scinote_template'
        }
      end

      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
      end

      it 'does not create a new report' do
        expect { action }.not_to change(Report, :count)
      end
    end

    context 'when template is missing' do
      let(:request_params) do
        {
          project_id: project.id,
          report_id: report.id
        }
      end

      it 'returns not_found status' do
        action
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #new_docx_template_values' do
    let(:action) { get :new_docx_template_values, params: request_params, format: 'json'}

    context 'when all params are provided' do
      let(:request_params) do
        {
          project_id: project.id,
          template: 'scinote_template',
          report_id: report.id
        }
      end

      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
      end
    end

    context 'when report_id is missing' do
      let(:request_params) do
        {
          project_id: project.id,
          template: 'scinote_template'
        }
      end

      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
      end

      it 'does not create a new report' do
        expect { action }.not_to change(Report, :count)
      end
    end

    context 'when template is missing' do
      let(:request_params) do
        {
          project_id: project.id,
          report_id: report.id
        }
      end

      it 'returns not_found status' do
        action
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET #document_preview' do
    let(:action) { get :document_preview, params: { id: report.id }, format: 'json'}

    context 'when all params are provided' do
      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
      end
    end
  end

  describe 'POST create' do
    context 'in JSON format' do
      before do
        allow(Reports::PdfJob).to receive(:perform_later)
      end

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
  end

  describe 'POST generate_docx' do
    context 'in JSON format' do
      let(:action) { post :generate_docx, params: params, format: :json }
      let(:params) do
        {
          project_id: project.id,
          id: report.id
        }
      end

      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :generate_docx_report))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'POST generate_pdf' do
    context 'in JSON format' do
      before do
        allow(Reports::PdfJob).to receive(:perform_later)
      end

      let(:action) { post :generate_pdf, params: params, format: :json }
      let(:params) do
        {
          project_id: project.id,
          id: report.id
        }
      end

      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :generate_pdf_report))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'POST save_pdf_to_inventory_item' do
    context 'in JSON format' do
      let(:action) { post :save_pdf_to_inventory_item, params: params, format: :json }
      let(:repository) { create :repository, team: team, created_by: user }
      let(:repository_column) { create(:repository_column, :asset_type, repository: repository) }
      let(:repository_row) { create :repository_row, created_by: user, repository: repository }
      let(:params) do
        {
          id: report.id,
          repository_id: repository.id,
          repository_column_id: repository_column.id,
          repository_item_id: repository_row.id
        }
      end

      before do
        report.pdf_file.attach(io: StringIO.new('%PDF-1.4 content'), filename: 'report.pdf',
                               content_type: 'application/pdf')
      end

      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
        expect(response.parsed_body['message']).to eq(
          I18n.t('projects.reports.new.save_PDF_to_inventory_modal.success_flash')
        )
      end

      it 'attaches a copy of the report pdf to the item cell' do
        expect { action }.to change { RepositoryAssetValue.count }.by(1)

        cell = repository_row.repository_cells.find_by(repository_column: repository_column)
        asset = cell.value.asset
        expect(asset.file.download).to eq '%PDF-1.4 content'
        expect(asset.file.filename.to_s).to eq 'report.pdf'
        expect(asset.created_by).to eq user
      end
    end
  end

  describe 'PUT update' do
    context 'in JSON format' do
      before do
        allow(Reports::PdfJob).to receive(:perform_later)
      end

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
  end

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

    it 'deletes the report and returns a success message' do
      report
      expect { action }.to change(Report, :count).by(-1)
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['message']).to eq I18n.t('projects.reports.index.modal_delete.success')
    end

    it 'skips reports the user cannot manage' do
      report
      allow(controller).to receive(:can_manage_report?).and_return(false)
      expect { action }.not_to change(Report, :count)
      expect(Activity.where(type_of: :delete_report)).to be_empty
    end

    it 'skips unknown report ids' do
      report
      expect { delete :destroy, params: { report_ids: [-1] } }.not_to change(Report, :count)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'additional actions' do
    let(:viewer_report_access) do
      allow(controller).to receive(:can_read_report?).and_return(false)
    end

    describe 'GET index (html)' do
      it 'renders the index page' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end

      it 'does not list reports from projects the user cannot read' do
        other_team = create :team
        other_project = create :project, team: other_team, created_by: other_team.created_by
        create :report, project: other_project, team: other_team, user: other_team.created_by
        report
        get :index, params: { page: 1, per_page: 20 }, format: :json
        expect(response.parsed_body['data'].map { |r| r['id'] }).to eq [report.id.to_s]
      end
    end

    describe 'GET download' do
      it 'redirects to the pdf file' do
        report.pdf_file.attach(io: StringIO.new('%PDF-1.4'), filename: 'report.pdf', content_type: 'application/pdf')
        get :download, params: { id: report.id }
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('report.pdf')
        expect(response.location).to include('disposition=attachment')
      end

      it 'redirects to the docx file when requested' do
        report.docx_file.attach(io: StringIO.new('docx'), filename: 'report.docx')
        get :download, params: { id: report.id, report_type: 'docx' }
        expect(response.location).to include('report.docx')
      end

      it 'returns 404 for unknown report' do
        get :download, params: { id: -1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'is forbidden without read permission' do
        viewer_report_access
        get :download, params: { id: report.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET new repositories' do
      include_context 'without compiled assets'
      render_views

      it 'lists live repositories and one snapshot per deleted repository, sorted by name' do
        live = create :repository, team: team, created_by: user, name: 'b live inventory'
        snapshot_source = create :repository, team: team, created_by: user, name: 'a deleted inventory'
        snapshot = create :repository_snapshot, original_repository: snapshot_source, my_module: my_module
        snapshot.update_column(:parent_id, nil)
        get :new
        expect(response).to have_http_status(:success)
        expect(assigns(:repositories)).to include(live, snapshot)
        expect(assigns(:repositories).index(live)).to be < assigns(:repositories).index(snapshot)
      end
    end

    describe 'GET new' do
      it 'is forbidden without create permission' do
        allow(controller).to receive(:can_create_reports?).and_return(false)
        get :new
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET edit' do
      it 'returns 404 for report from another team' do
        get :edit, params: { project_id: project.id, id: -1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'is forbidden without manage permission' do
        allow(controller).to receive(:can_manage_report?).and_return(false)
        get :edit, params: { project_id: project.id, id: report.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'assigns project contents from report elements' do
        create :report_element, report: report, experiment: experiment, type_of: :experiment
        get :edit, params: { project_id: project.id, id: report.id }
        expect(assigns(:project_contents)[:experiments]).to eq [experiment.id]
        expect(assigns(:active_docx_template)).to eq 'scinote_template'
        expect(assigns(:edit)).to be true
      end
    end

    describe 'GET #new_template_values' do
      it 'is forbidden when the user cannot manage the given report' do
        allow(controller).to receive(:can_manage_report?).and_return(false)
        get :new_template_values,
            params: { project_id: project.id, template: 'scinote_template', report_id: report.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'is forbidden when the user cannot create reports' do
        allow(controller).to receive(:can_create_reports?).and_return(false)
        get :new_template_values, params: { project_id: project.id, template: 'scinote_template' }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      context 'with views rendered' do
        render_views

        it 'renders the no template values partial when template has no editor' do
          get :new_template_values, params: { project_id: project.id, template: 'scinote_template' }, format: :json
          expect(response.parsed_body['html']).to include(
            I18n.t('projects.reports.wizard.first_step.values_editor.no_values_description')
          )
        end
      end

      it 'returns 404 for unknown project' do
        get :new_template_values, params: { project_id: -1, template: 'scinote_template' }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'is forbidden without project read permission' do
        allow(controller).to receive(:can_read_project?).and_return(false)
        get :new_template_values, params: { project_id: project.id, template: 'scinote_template' }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET #new_docx_template_values' do
      it 'is forbidden when the user cannot manage the given report' do
        allow(controller).to receive(:can_manage_report?).and_return(false)
        get :new_docx_template_values,
            params: { project_id: project.id, template: 'scinote_template', report_id: report.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'is forbidden when the user cannot create reports' do
        allow(controller).to receive(:can_create_reports?).and_return(false)
        get :new_docx_template_values, params: { project_id: project.id, template: 'scinote_template' },
                                       format: :json
        expect(response).to have_http_status(:forbidden)
      end

      context 'with views rendered' do
        render_views

        it 'renders the no template values partial when template has no editor' do
          get :new_docx_template_values, params: { project_id: project.id, template: 'scinote_template' },
                                         format: :json
          expect(response.parsed_body['html']).to include(
            I18n.t('projects.reports.wizard.first_step.values_editor.no_values_description')
          )
        end
      end
    end

    describe 'POST create' do
      before { allow(Reports::PdfJob).to receive(:perform_later) }

      it 'creates report, enqueues pdf job and redirects' do
        expect do
          post :create, params: { project_id: project.id,
                                  report: { name: 'Brand new report', settings: Report::DEFAULT_SETTINGS },
                                  project_content: { experiments: [{ id: experiment.id, my_module_ids: [my_module.id] }] },
                                  template_values: [] }
        end.to change(Report, :count).by(1)
        new_report = Report.order(:created_at).last
        expect(response).to redirect_to(reports_path)
        expect(new_report.name).to eq 'Brand new report'
        expect(new_report.user).to eq user
        expect(new_report).to be_pdf_processing
        expect(Reports::PdfJob).to have_received(:perform_later).with(new_report.id, user_id: user.id)
      end

      it 'still creates the report and logs the error when enqueuing the pdf job fails' do
        allow(Reports::PdfJob).to receive(:perform_later).and_raise(ActiveRecord::ActiveRecordError, 'queue down')
        allow(Rails.logger).to receive(:error)
        expect do
          post :create, params: { project_id: project.id,
                                  report: { name: 'Queue failure report', settings: Report::DEFAULT_SETTINGS },
                                  project_content: { experiments: [{ id: experiment.id, my_module_ids: [my_module.id] }] },
                                  template_values: [] }
        end.to change(Report, :count).by(1)
        expect(response).to redirect_to(reports_path)
        expect(Rails.logger).to have_received(:error).with('queue down')
      end

      it 'returns errors for invalid report' do
        expect do
          post :create, params: { project_id: project.id,
                                  report: { name: 'a' * (Constants::NAME_MAX_LENGTH + 1) },
                                  project_content: { experiments: [] },
                                  template_values: [] }, format: :json
        end.not_to change(Report, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to be_an(Array)
        expect(Reports::PdfJob).not_to have_received(:perform_later)
      end

      it 'is forbidden without create permission' do
        allow(controller).to receive(:can_create_reports?).and_return(false)
        expect do
          post :create, params: { project_id: project.id, report: { name: 'Nope' } }
        end.not_to change(Report, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns 404 for unknown project' do
        post :create, params: { project_id: -1, report: { name: 'Nope' } }
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'PUT update' do
      before { allow(Reports::PdfJob).to receive(:perform_later) }

      it 'updates the report name' do
        put :update, params: { project_id: project.id, id: report.id,
                               report: { name: 'Renamed report' },
                               project_content: { experiments: [{ id: experiment.id, my_module_ids: [my_module.id] }] },
                               template_values: [] }
        expect(response).to redirect_to(reports_path)
        expect(report.reload.name).to eq 'Renamed report'
        expect(report.last_modified_by).to eq user
      end

      it 'returns errors for invalid name' do
        put :update, params: { project_id: project.id, id: report.id,
                               report: { name: 'a' * (Constants::NAME_MAX_LENGTH + 1) },
                               project_content: { experiments: [] },
                               template_values: [] }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(report.reload.name).to eq 'test repot A1'
      end

      it 'is forbidden without manage permission' do
        allow(controller).to receive(:can_manage_report?).and_return(false)
        put :update, params: { project_id: project.id, id: report.id, report: { name: 'Renamed report' } }
        expect(response).to have_http_status(:forbidden)
        expect(report.reload.name).to eq 'test repot A1'
      end
    end

    describe 'GET status' do
      it 'returns serialized report' do
        get :status, params: { project_id: project.id, id: report.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig('data', 'id')).to eq report.id.to_s
      end

      it 'is forbidden without read permission' do
        viewer_report_access
        get :status, params: { project_id: project.id, id: report.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST generate_pdf' do
      it 'is forbidden without manage permission' do
        allow(Reports::PdfJob).to receive(:perform_later)
        allow(controller).to receive(:can_manage_report?).and_return(false)
        post :generate_pdf, params: { project_id: project.id, id: report.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(Reports::PdfJob).not_to have_received(:perform_later)
      end

      it 'sets template and processing status before enqueueing' do
        allow(Reports::PdfJob).to receive(:perform_later)
        report.update!(settings: { 'all_tasks' => true })
        post :generate_pdf, params: { project_id: project.id, id: report.id }, format: :json
        report.reload
        expect(report).to be_pdf_processing
        expect(report.settings['template']).to eq 'scinote_template'
        expect(Reports::PdfJob).to have_received(:perform_later).with(report.id, user_id: user.id)
      end
    end

    describe 'POST generate_docx' do
      it 'enqueues docx job and marks report as processing' do
        allow(Reports::DocxJob).to receive(:perform_later)
        post :generate_docx, params: { project_id: project.id, id: report.id }, format: :json
        expect(report.reload).to be_docx_processing
        expect(Reports::DocxJob).to have_received(:perform_later)
          .with(report.id, hash_including(user_id: user.id, root_url: kind_of(String)))
      end

      it 'is forbidden without manage permission' do
        allow(controller).to receive(:can_manage_report?).and_return(false)
        post :generate_docx, params: { project_id: project.id, id: report.id }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(report.reload).not_to be_docx_processing
      end
    end

    describe 'GET save_pdf_to_inventory_modal' do
      it 'renders modal html' do
        # reports_controller.rb:231 renders partial 'reports/save_PDF_to_inventory_modal' which no longer
        # exists (the modal moved to Vue), so the endpoint raises ActionView::MissingTemplate.
        pending 'bug: save_pdf_to_inventory_modal renders a missing partial'
        get :save_pdf_to_inventory_modal, params: { id: report.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['html']).to be_present
      end

      it 'is forbidden without read permission' do
        viewer_report_access
        get :save_pdf_to_inventory_modal, params: { id: report.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST save_pdf_to_inventory_item' do
      let(:params) { { id: report.id, repository_id: 1, repository_column_id: 1, repository_item_id: 1 } }

      it 'returns 404 when the report has no pdf' do
        post :save_pdf_to_inventory_item, params: params, format: :json
        expect(response).to have_http_status(:not_found)
      end

      context 'when report has a pdf' do
        before do
          report.pdf_file.attach(io: StringIO.new('%PDF-1.4'), filename: 'report.pdf', content_type: 'application/pdf')
        end

        it 'returns errors when saving fails' do
          service = instance_double(ReportActions::SavePdfToInventoryItem, save: false, error_messages: 'Broken')
          allow(ReportActions::SavePdfToInventoryItem).to receive(:new).and_return(service)
          post :save_pdf_to_inventory_item, params: params, format: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.parsed_body['message']).to eq 'Broken'
        end

        it 'returns forbidden when user cannot create rows in the repository' do
          repository = create :repository, team: team, created_by: user
          # can_create_repository_rows? is resolved through Canaid's method_missing, so the stub needs
          # partial double verification switched off.
          without_partial_double_verification do
            allow_any_instance_of(ReportActions::SavePdfToInventoryItem)
              .to receive(:can_create_repository_rows?).and_return(false)
          end
          post :save_pdf_to_inventory_item, params: params.merge(repository_id: repository.id), format: :json
          expect(response).to have_http_status(:forbidden)
          expect(response.parsed_body['message']).to eq I18n.t('projects.reports.new.no_permissions')
        end

        it 'returns not found or forbidden for a non-existing repository' do
          # SavePdfToInventoryItem#load_repository_collaborators does not guard against a nil repository
          # and raises, which the controller turns into a 500.
          pending 'bug: save_pdf_to_inventory_item answers 500 for a non-existing repository'
          post :save_pdf_to_inventory_item, params: params.merge(repository_id: -1), format: :json
          expect(response.status).to be_in([403, 404])
        end

        it 'returns internal server error on unexpected errors' do
          allow(ReportActions::SavePdfToInventoryItem).to receive(:new).and_raise(StandardError, 'kaboom')
          post :save_pdf_to_inventory_item, params: params, format: :json
          expect(response).to have_http_status(:internal_server_error)
          expect(response.parsed_body['message']).to eq 'kaboom'
        end
      end
    end

    describe 'GET project_contents' do
      render_views

      it 'renders project contents html' do
        get :project_contents, params: { project_id: project.id }, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['html']).to include(experiment.name)
      end

      it 'is forbidden without project read permission' do
        allow(controller).to receive(:can_read_project?).and_return(false)
        get :project_contents, params: { project_id: project.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET available_repositories' do
      it 'returns repositories where user can manage rows' do
        repository = create :repository, team: team, created_by: user, name: 'Inventory for PDF'
        get :available_repositories, format: :json
        expect(response.parsed_body['data']).to include([repository.id, 'Inventory for PDF'])
      end

      it 'omits repositories where user cannot manage rows' do
        create :repository, team: team, created_by: user, name: 'Inventory for PDF'
        allow(controller).to receive(:can_manage_repository_rows?).and_return(false)
        get :available_repositories, format: :json
        expect(response.parsed_body['data']).to eq []
      end
    end

    describe 'GET document_preview' do
      it 'is forbidden without read permission' do
        viewer_report_access
        get :document_preview, params: { id: report.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST actions_toolbar' do
      it 'returns toolbar actions for selected reports' do
        post :actions_toolbar, params: { items: [{ id: report.id }].to_json }, format: :json
        names = response.parsed_body['actions'].map { |a| a['name'] }
        expect(names).to include('edit', 'delete')
      end

      it 'returns no actions for empty selection' do
        post :actions_toolbar, params: { items: [].to_json }, format: :json
        expect(response.parsed_body['actions']).to eq []
      end
    end
  end
end
