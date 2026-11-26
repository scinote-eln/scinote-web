# frozen_string_literal: true

require 'rails_helper'

describe Reports::DocxTemplateJob, type: :job do
  let(:user) { create(:user).tap(&:confirm) }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:report) { create :report, user: user, team: team, project: project }
  let(:odt_report) { instance_double(ODFReport::Report) }
  let(:odf_builder) { double('odf builder').as_null_object }
  let(:converted_path) { Rails.root.join('tmp', "docx_template_job_spec_#{SecureRandom.hex(4)}.docx") }
  let(:root_url) { 'http://localhost:3000' }
  let(:converter_args) { [] }

  before do
    report.odt_template_file.attach(io: StringIO.new('odt template'), filename: 'template.odt')
    File.binwrite(converted_path, 'converted docx')
    allow(DeliveryNotification).to receive(:send_notifications)
    allow(Reports::DocxPreviewJob).to receive(:perform_now)
    allow(odt_report).to receive(:generate) { |path| File.binwrite(path, 'generated odt') }
    allow(ODFReport::Report).to receive(:new) do |path, &block|
      expect(File.binread(path)).to eq 'odt template'
      block.call(odf_builder)
      odt_report
    end
    allow(Reports::ConvertFileFormatService).to receive(:convert) do |file, format|
      converter_args << [file.path, format]
      File.open(converted_path)
    end
  end

  after { FileUtils.rm_f(converted_path) }

  def run_job
    described_class.perform_now(report.id, user_id: user.id, root_url: root_url)
  end

  describe '#perform' do
    it 'fills the odt template, converts it to docx and attaches it' do
      run_job

      expect(odf_builder).to have_received(:add_field).with(:id, report.id.to_s)
      expect(odf_builder).to have_received(:add_field).with(:created_by, report.created_by)
      expect(odf_builder).to have_received(:add_field)
        .with(:created_at, report.created_at.strftime('%d/%m/%Y - %H:%M'))
      expect(odf_builder).to have_received(:add_text).with(:notes, '<h1>Notes</h1>')
      expect(odf_builder).to have_received(:add_checklist).with(:form, array_including(text: 'Design approved', checked: true))

      expect(converter_args.size).to eq 1
      expect(converter_args.first[0]).to end_with('.odt')
      expect(converter_args.first[1]).to eq 'docx'
      expect(report.reload.docx_file).to be_attached
      expect(report.docx_file.filename.to_s).to eq 'report.docx'
      expect(report.docx_file.download).to eq 'converted docx'
      expect(report).to be_docx_ready
    end

    it 'notifies the user, builds the preview and removes the converted file' do
      run_job

      expect(DeliveryNotification).to have_received(:send_notifications).with(
        hash_including(
          title: I18n.t('projects.reports.index.generation.completed_docx_notification_title'),
          subject_id: report.id,
          subject_class: 'Report',
          subject_name: report.name,
          report_type: 'docx',
          user_id: user.id
        )
      )
      expect(Reports::DocxPreviewJob).to have_received(:perform_now).with(report.id)
      expect(File.exist?(converted_path)).to be false
      expect(I18n.backend.date_format).to eq Constants::DEFAULT_DATE_FORMAT
    end

    context 'when the conversion fails' do
      before do
        allow(Reports::ConvertFileFormatService).to receive(:convert).and_raise(StandardError, 'soffice missing')
      end

      it 'marks the report as docx_error, logs and re-raises' do
        allow(Rails.logger).to receive(:error)

        expect { run_job }.to raise_error(StandardError, 'soffice missing')

        expect(Rails.logger).to have_received(:error)
          .with(/Couldn't generate DOCX for Report with id: #{report.id}.*soffice missing/m)
        expect(report.reload).to be_docx_error
        expect(report.docx_file).not_to be_attached
        expect(Reports::DocxPreviewJob).not_to have_received(:perform_now)
      end
    end

    it 'raises RecordNotFound for an unknown report' do
      expect { described_class.perform_now(-1, user_id: user.id, root_url: root_url) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
