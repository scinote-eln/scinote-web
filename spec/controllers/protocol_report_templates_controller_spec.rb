# frozen_string_literal: true

require 'rails_helper'

describe ProtocolReportTemplatesController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }

  let!(:protocol) { create :protocol, :in_repository_draft, team: team, added_by: user }
  let(:odt_type) { 'application/vnd.oasis.opendocument.text' }
  let(:json) { JSON.parse(response.body) }

  def create_template(subject: protocol, name: 'Template', filename: 'tpl.odt', content_type: odt_type, attach: :odt)
    template = ReportTemplate.create!(name: name, subject: subject)
    file = StringIO.new('template content')
    case attach
    when :docx then template.docx_template_file.attach(io: file, filename: filename, content_type: content_type)
    else template.odt_template_file.attach(io: file, filename: filename, content_type: content_type)
    end
    template
  end

  def signed_blob(filename)
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new('file'), filename: filename,
                                           content_type: 'application/octet-stream').signed_id
  end

  before do
    user.update!(current_team_id: team.id)
    allow(ReportTemplate).to receive(:analytical_reporting_enabled?).and_return(true)
  end

  describe 'before actions' do
    it 'returns 404 for an unknown protocol' do
      get :index, params: { protocol_id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 when analytical reporting is disabled' do
      allow(ReportTemplate).to receive(:analytical_reporting_enabled?).and_return(false)
      get :index, params: { protocol_id: protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET index' do
    let!(:older) { create_template(name: 'Older').tap { |t| t.update_column(:created_at, 2.days.ago) } }
    let!(:newer) { create_template(name: 'Newer') }

    it 'lists templates of the protocol newest first' do
      create_template(subject: create(:protocol, :in_repository_draft, team: team, added_by: user), name: 'Foreign')
      get :index, params: { protocol_id: protocol.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['templates'].map { |t| t['name'] }).to eq %w(Newer Older)
      expect(json['templates'].first).to include('id' => newer.id,
                                                'preview' => preview_protocol_protocol_report_template_path(protocol, newer))
    end

    it 'renders html with breadcrumbs and inline name editing' do
      get :index, params: { protocol_id: protocol.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:active_tab)).to eq :protocol_report_templates
      expect(assigns(:breadcrumbs_items).map { |i| i[:label] }).to eq [I18n.t('breadcrumbs.protocols'), protocol.name]
      expect(assigns(:inline_editable_title_config)[:path_to_update]).to eq name_protocol_path(protocol)
    end

    it 'prefixes breadcrumbs for archived protocols' do
      protocol.update_columns(archived: true)
      get :index, params: { protocol_id: protocol.id }

      expect(assigns(:breadcrumbs_items).map { |i| i[:label] }).to all(start_with(I18n.t('labels.archived')))
    end

    it 'returns forbidden without read permissions' do
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      get :index, params: { protocol_id: protocol.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST create' do
    before do
      allow(ReportTemplates::ConvertDocxToOdtJob).to receive(:perform_later)
      allow(ReportTemplates::ReportTemplatePreviewJob).to receive(:perform_later)
    end

    it 'creates an odt template, logs an activity and schedules the preview' do
      expect do
        post :create, params: { protocol_id: protocol.id, name: 'My template', file: signed_blob('my.odt') },
                      format: :json
      end.to change { protocol.report_templates.count }.by(1)
                                                       .and change { Activity.where(type_of: :report_template_added).count }.by(1)

      template = protocol.report_templates.last
      expect(response).to have_http_status(:no_content)
      expect(template.name).to eq 'My template'
      expect(template.odt_template_file).to be_attached
      expect(template.docx_template_file).not_to be_attached
      expect(ReportTemplates::ReportTemplatePreviewJob).to have_received(:perform_later).with(template.id)
      expect(ReportTemplates::ConvertDocxToOdtJob).not_to have_received(:perform_later)
    end

    it 'creates a docx template and schedules the conversion' do
      post :create, params: { protocol_id: protocol.id, name: 'Word', file: signed_blob('my.DOCX') }, format: :json

      template = protocol.report_templates.last
      expect(template.docx_template_file).to be_attached
      expect(template.odt_template_file).not_to be_attached
      expect(ReportTemplates::ConvertDocxToOdtJob).to have_received(:perform_later).with(template.id)
      expect(ReportTemplates::ReportTemplatePreviewJob).not_to have_received(:perform_later)
    end

    it 'does not create anything for an invalid signed blob id' do
      expect do
        expect do
          post :create, params: { protocol_id: protocol.id, name: 'x', file: 'invalid' }, format: :json
        end.to raise_error(ActiveSupport::MessageVerifier::InvalidSignature)
      end.not_to(change { ReportTemplate.count })
    end

    it 'returns forbidden without manage permissions' do
      allow(controller).to receive(:can_manage_protocol_draft_in_repository?).and_return(false)

      expect do
        post :create, params: { protocol_id: protocol.id, name: 'x', file: signed_blob('my.odt') }, format: :json
      end.not_to(change { ReportTemplate.count })
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET input_tags' do
    it 'returns the tags built by the tag service' do
      tags = [{ label: 'General', inputs: [] }]
      allow_any_instance_of(ProtocolReportTemplates::TagService).to receive(:tags).and_return(tags)

      get :input_tags, params: { protocol_id: protocol.id }

      expect(response).to have_http_status(:ok)
      expect(json).to eq [{ 'label' => 'General', 'inputs' => [] }]
    end

    it 'includes the default placeholders for a real protocol' do
      get :input_tags, params: { protocol_id: protocol.id }

      expect(json.first['label']).to eq 'General task data'
    end

    it 'returns forbidden without read permissions' do
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      get :input_tags, params: { protocol_id: protocol.id }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET download' do
    it 'redirects to the odt blob as an attachment' do
      template = create_template
      get :download, params: { protocol_id: protocol.id, id: template.id }

      expect(response).to redirect_to(rails_blob_path(template.odt_template_file, disposition: 'attachment'))
    end

    it 'prefers the docx file when present' do
      template = create_template(attach: :docx, filename: 'tpl.docx')
      get :download, params: { protocol_id: protocol.id, id: template.id }

      expect(response).to redirect_to(rails_blob_path(template.docx_template_file, disposition: 'attachment'))
    end

    it 'returns 404 for a template of another protocol' do
      other = create_template(subject: create(:protocol, :in_repository_draft, team: team, added_by: user))
      get :download, params: { protocol_id: protocol.id, id: other.id }

      expect(response).to have_http_status(:not_found)
    end

    it 'returns forbidden without read permissions' do
      template = create_template
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      get :download, params: { protocol_id: protocol.id, id: template.id }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE destroy' do
    let!(:template) { create_template }

    it 'deletes the template and logs an activity' do
      expect do
        delete :destroy, params: { protocol_id: protocol.id, id: template.id }
      end.to change { ReportTemplate.count }.by(-1)
                                            .and change { Activity.where(type_of: :report_template_deleted).count }.by(1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 and rolls back when destroying fails' do
      allow_any_instance_of(ReportTemplate).to receive(:destroy!).and_raise(ActiveRecord::RecordInvalid.new(template))

      expect do
        delete :destroy, params: { protocol_id: protocol.id, id: template.id }
      end.not_to(change { [ReportTemplate.count, Activity.where(type_of: :report_template_deleted).count] })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error']).to be_present
    end

    it 'returns forbidden without read permissions' do
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      delete :destroy, params: { protocol_id: protocol.id, id: template.id }

      expect(response).to have_http_status(:forbidden)
      expect(ReportTemplate.exists?(template.id)).to be true
    end

    it 'returns 404 for an unknown template' do
      delete :destroy, params: { protocol_id: protocol.id, id: -1 }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET preview' do
    it 'renders the preview partial into json' do
      template = create_template
      get :preview, params: { protocol_id: protocol.id, id: template.id }

      expect(response).to have_http_status(:ok)
      expect(json).to have_key('html')
    end

    it 'returns forbidden without read permissions' do
      template = create_template
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      get :preview, params: { protocol_id: protocol.id, id: template.id }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET pdf_preview_path' do
    let(:template) { create_template }
    let(:action) { get :pdf_preview_path, params: { protocol_id: protocol.id, id: template.id } }

    it 'returns 406 when the document cannot be previewed' do
      allow(controller).to receive(:previewable_document?).and_return(false)
      action

      expect(response).to have_http_status(:not_acceptable)
    end

    it 'returns 202 while the preview is not generated yet' do
      allow(controller).to receive(:previewable_document?).and_return(true)
      action

      expect(response).to have_http_status(:accepted)
    end

    it 'redirects to the generated preview' do
      allow(controller).to receive(:previewable_document?).and_return(true)
      template.odt_template_file_preview.attach(io: StringIO.new('%PDF'), filename: 'tpl.pdf',
                                                content_type: 'application/pdf')
      action

      expect(response).to redirect_to(rails_blob_path(template.odt_template_file_preview))
    end

    it 'returns forbidden without read permissions' do
      allow(controller).to receive(:can_read_protocol_in_repository?).and_return(false)
      action

      expect(response).to have_http_status(:forbidden)
    end
  end
end
