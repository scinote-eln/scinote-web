# frozen_string_literal: true

require 'rails_helper'

describe Reports::DocxJob, type: :job do
  let(:user) { create(:user).tap(&:confirm) }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:report) { create :report, user: user, team: team, project: project }
  let(:docx_builder) { instance_double(Reports::Docx, draw: true) }
  let(:root_url) { 'http://localhost:3000' }

  before do
    allow(DeliveryNotification).to receive(:send_notifications)
    allow(Reports::DocxPreviewJob).to receive(:perform_now)
    allow(Reports::Docx).to receive(:new).and_return(docx_builder)
  end

  def run_job
    described_class.perform_now(report.id, user_id: user.id, root_url: root_url)
  end

  describe '#perform' do
    it 'draws the report, attaches the docx, notifies the user and marks the report ready' do
      run_job

      expect(Reports::Docx).to have_received(:new)
        .with(report, an_instance_of(Caracal::Document), user: user, scinote_url: root_url)
      expect(docx_builder).to have_received(:draw)
      expect(report.reload.docx_file).to be_attached
      expect(report.docx_file.filename.to_s).to eq 'report.docx'
      expect(report).to be_docx_ready
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
    end

    it 'saves a real docx archive produced by Caracal' do
      allow(docx_builder).to receive(:draw) { |*| nil }
      allow(Reports::Docx).to receive(:new) do |_report, docx, **|
        docx.p 'Hello report'
        docx_builder
      end

      run_job

      Tempfile.create(['check', '.docx'], binmode: true) do |file|
        file.write(report.reload.docx_file.download)
        file.flush
        names = Zip::File.open(file.path) { |zip| zip.entries.map(&:name) }
        expect(names).to include('word/document.xml')
      end
    end

    it 'uses the user date format only while the report is generated' do
      user.settings[:date_format] = 'dd/mm/yyyy'
      user.save!
      seen = nil
      allow(docx_builder).to receive(:draw) { seen = I18n.backend.date_format }

      run_job

      expect(seen).to eq 'dd/mm/yyyy'
      expect(I18n.backend.date_format).to eq Constants::DEFAULT_DATE_FORMAT
    end

    context 'when drawing fails' do
      before { allow(docx_builder).to receive(:draw).and_raise(StandardError, 'caracal exploded') }

      it 'marks the report as docx_error, logs and re-raises' do
        allow(Rails.logger).to receive(:error)

        expect { run_job }.to raise_error(StandardError, 'caracal exploded')

        expect(Rails.logger).to have_received(:error)
          .with(/Couldn't generate DOCX for Report with id: #{report.id}.*caracal exploded/m)
        expect(report.reload).to be_docx_error
        expect(report.docx_file).not_to be_attached
        expect(I18n.backend.date_format).to eq Constants::DEFAULT_DATE_FORMAT
      end

      it 'sends an error notification linking to the reports page' do
        expect { run_job }.to raise_error(StandardError)

        expect(DeliveryNotification).to have_received(:send_notifications).with(
          hash_including(
            title: I18n.t('projects.reports.index.generation.error_docx_notification_title'),
            error: true,
            user_id: user.id,
            message: a_string_including(Rails.application.routes.url_helpers.reports_path(team: team.id))
          )
        )
      end

      it 'links the notification to the docx preview when a docx is already attached' do
        report.docx_file.attach(io: StringIO.new('old'), filename: 'old.docx')

        expect { run_job }.to raise_error(StandardError)

        expect(DeliveryNotification).to have_received(:send_notifications).with(
          hash_including(error: true,
                         message: a_string_including("preview_report_id=#{report.id}", 'preview_type=docx'))
        )
      end
    end

    it 'raises RecordNotFound for an unknown report' do
      expect { described_class.perform_now(-1, user_id: user.id, root_url: root_url) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'refuses to be enqueued without a user_id' do
      expect { described_class.perform_later(report.id, root_url: root_url) }.to raise_error(ArgumentError, /user_id/)
    end
  end
end
