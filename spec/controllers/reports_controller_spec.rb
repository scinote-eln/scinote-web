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
      before do
        allow(controller).to receive(:current_team).and_return(team)
        allow(team.reports).to receive(:find_by).and_return(report)
        allow(report.pdf_file).to receive(:attached?).and_return(true)
        allow(ReportActions::SavePdfToInventoryItem).to receive(:new).and_return(service)
      end

      let(:action) { post :save_pdf_to_inventory_item, params: params, format: :json }
      let(:repository) { create :repository, team: team, created_by: user }
      let(:repository_column) { create(:repository_column, :asset_type, repository: repository) }
      let(:repository_row) { create :repository_row, created_by: user, repository: repository }
      let(:service) { double("SavePdfToInventoryItem", save: true) }
      
      let(:params) do
        {
          id: report.id,
          repository_id: repository.id,
          repository_column_id: repository_column.id,
          repository_item_id: repository_row.id
        }
      end

      it 'returns success and JSON content' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq('application/json')
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
  end
end
