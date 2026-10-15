# frozen_string_literal: true

require 'rails_helper'

describe Reports::PdfJob, type: :job do
  let(:user) { create(:user).tap(&:confirm) }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:project) do
    create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id
  end
  let!(:project_assignment) { create_user_assignment(project, owner_role, user) }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: user, my_module_status: MyModuleStatus.first
  end
  let(:report) { create :report, user: user, team: team, project: project }
  let(:grover) { instance_double(Grover) }
  let(:grover_calls) { [] }

  before do
    MyModuleStatusFlow.ensure_default
    user.update!(current_team_id: team.id)
    allow(Grover).to receive(:new) do |html, **options|
      grover_calls << { html: html, options: options }
      grover
    end
    allow(grover).to receive(:to_pdf) { |path| File.binwrite(path, '%PDF-1.4 fake') }
    allow(DeliveryNotification).to receive(:send_notifications)
  end

  def run_job(report_to_run = report)
    described_class.perform_now(report_to_run.id, user_id: user.id)
  end

  describe '#perform' do
    it 'renders the report, hands it to Grover and attaches the pdf' do
      run_job

      report.reload
      expect(report.pdf_file).to be_attached
      expect(report.pdf_file.filename.to_s).to eq 'report.pdf'
      expect(report.pdf_file.download).to eq '%PDF-1.4 fake'
      expect(report).to be_pdf_ready
    end

    it 'passes the header/footer html, margins and page range to Grover' do
      run_job

      call = grover_calls.first
      expect(call[:html]).to start_with('<!DOCTYPE html>')
      expect(call[:options]).to include(
        format: 'A4',
        print_background: true,
        display_header_footer: true,
        margin: { top: '2cm', bottom: '2cm', left: '1cm', right: '1.5cm' },
        page_ranges: '1-999999',
        emulate_media: 'screen'
      )
      expect(call[:options][:header_template]).to be_a(String).and(be_present)
      expect(call[:options][:footer_template]).to be_a(String).and(be_present)
    end

    it 'notifies the user that the pdf is ready' do
      run_job

      expect(DeliveryNotification).to have_received(:send_notifications).with(
        hash_including(
          title: I18n.t('projects.reports.index.generation.completed_pdf_notification_title'),
          subject_id: report.id,
          subject_class: 'Report',
          subject_name: report.name,
          report_type: 'pdf',
          user_id: user.id
        )
      )
    end

    it 'uses the user date format while rendering and resets global state afterwards' do
      user.settings[:date_format] = 'dd/mm/yyyy'
      user.save!
      formats = []
      allow(Grover).to receive(:new) do |*|
        formats << I18n.backend.date_format
        Rails.application.config.x.custom_sanitizer_config.tap { |c| formats << c[:protocols] }
        grover
      end

      run_job

      expect(formats.first).to eq 'dd/mm/yyyy'
      expect(formats.last).to eq('a' => { 'href' => ['http', 'https', :relative] }, 'img' => { 'src' => %w(data) })
      expect(I18n.backend.date_format).to eq Constants::DEFAULT_DATE_FORMAT
      expect(Rails.application.config.x.custom_sanitizer_config).to be_nil
    end

    it 'falls back to the first known template when the report template is unknown' do
      report.update!(settings: report.settings.merge(template: 'does_not_exist'))

      run_job

      expect(report.reload).to be_pdf_ready
      expect(grover_calls.first[:options][:header_template]).to be_present
    end

    context 'when generating the pdf fails' do
      before { allow(grover).to receive(:to_pdf).and_raise(StandardError, 'chromium crashed') }

      it 'marks the report as errored and re-raises' do
        expect(Rails.logger).to receive(:error).with(/Couldn't generate PDF for Report with id: #{report.id}.*chromium/m)
        allow(Rails.logger).to receive(:error)

        expect { run_job }.to raise_error(StandardError, 'chromium crashed')

        expect(report.reload).to be_pdf_error
        expect(report.pdf_file).not_to be_attached
      end

      it 'sends an error notification linking to the reports page' do
        expect { run_job }.to raise_error(StandardError)

        expect(DeliveryNotification).to have_received(:send_notifications).with(
          hash_including(
            title: I18n.t('projects.reports.index.generation.error_pdf_notification_title'),
            error: true,
            user_id: user.id,
            message: a_string_including(
              Rails.application.routes.url_helpers.reports_path(team: team.id), ERB::Util.html_escape(report.name)
            )
          )
        )
      end

      it 'links the notification to the pdf preview when a pdf is already attached' do
        report.pdf_file.attach(io: StringIO.new('old'), filename: 'old.pdf')

        expect { run_job }.to raise_error(StandardError)

        expect(DeliveryNotification).to have_received(:send_notifications).with(
          hash_including(
            error: true,
            message: a_string_including("preview_report_id=#{report.id}", 'preview_type=pdf')
          )
        )
      end
    end

    it 'raises RecordNotFound when the report does not exist' do
      # bug: the ensure block calls @file.close on nil, so a NoMethodError hides the RecordNotFound
      pending 'bug: missing report raises NoMethodError (nil @file.close in ensure) instead of RecordNotFound'

      expect { described_class.perform_now(-1, user_id: user.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'cover page handling' do
    let(:cover_pathname) do
      Rails.root.join('app', 'views', 'reports', 'templates', 'scinote_template', 'cover.html.erb')
    end
    let(:fake_renderer) { instance_double(ActionController::Renderer, render_to_string: '<html>cover</html>') }
    let(:renderer_class) { double(defaults: {}, new: fake_renderer) }
    let(:system_calls) { [] }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(cover_pathname).and_return(true)
      allow_any_instance_of(Pathname).to receive(:exist?).and_wrap_original do |original, *args|
        original.receiver == cover_pathname || original.call(*args)
      end
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(cover_pathname).and_return('<!-- cover_pages_count:2 -->')
      allow(ApplicationController).to receive(:renderer).and_return(renderer_class)
      allow(IO).to receive(:popen).and_yield(StringIO.new("Title: x\nPages:          7\n"))
      allow_any_instance_of(described_class).to receive(:system) do |_job, *args|
        system_calls << args
        File.binwrite(args.last, '%PDF merged')
        true
      end
    end

    it 'renders the cover separately, merges it with pdfunite and skips the cover pages in the body' do
      run_job

      expect(grover_calls.size).to eq 2
      expect(grover_calls.first[:options][:page_ranges]).to eq '3-999999'
      expect(grover_calls.last[:html]).to eq '<html>cover</html>'
      expect(system_calls.size).to eq 1
      expect(system_calls.first.first).to eq 'pdfunite'
      expect(report.reload.pdf_file.download).to eq '%PDF merged'
      expect(report).to be_pdf_ready
    end

    it 'fails the report when pdfunite cannot merge the title page' do
      allow_any_instance_of(described_class).to receive(:system).and_return(false)

      expect { run_job }.to raise_error(StandardError, 'There was an error merging report and title page')
      expect(report.reload).to be_pdf_error
    end

    it 'counts a single cover page when the cover has no page count comment' do
      allow(File).to receive(:read).with(cover_pathname).and_return('<div>cover</div>')

      run_job

      expect(grover_calls.first[:options][:page_ranges]).to eq '2-999999'
    end
  end

  describe 'result file previews' do
    let(:result) { create :result, my_module: my_module, user: user }
    let(:asset) { create :asset, team: team }
    let(:preview_asset_blob) { ActiveStorage::Blob.find_by!(filename: 'doc.docx') }
    let(:merge_calls) { [] }

    before do
      report.update!(settings: report.settings.deep_merge(task: { file_results_previews: true }))
      create :report_element, report: report, type_of: :my_module, my_module: my_module
      create :result_asset, result: result, asset: asset
      asset.file.attach(io: StringIO.new('docx content'), filename: 'doc.docx')
      allow(Open3).to receive(:capture3) do |*args|
        merge_calls << args
        File.binwrite(args.last, '%PDF merged previews')
        ['', '', instance_double(Process::Status, success?: true)]
      end
    end

    it 'generates missing previews and merges them into the report' do
      expect(PdfPreviewJob).to receive(:perform_now).with(asset.id) do
        asset.file_pdf_preview.attach(io: StringIO.new('%PDF preview'), filename: 'doc.pdf')
      end

      run_job

      expect(merge_calls.size).to eq 1
      expect(merge_calls.first.first).to eq 'pdfunite'
      expect(report.reload.pdf_file.download).to eq '%PDF merged previews'
      expect(report).to be_pdf_ready
    end

    it 'does not regenerate a preview that is newer than the file' do
      asset.file_pdf_preview.attach(io: StringIO.new('%PDF preview'), filename: 'doc.pdf')
      expect(PdfPreviewJob).not_to receive(:perform_now)

      run_job

      expect(merge_calls.size).to eq 1
    end

    it 'ignores assets that cannot be previewed' do
      asset.file.attach(io: StringIO.new('img'), filename: 'picture.png')
      expect(PdfPreviewJob).not_to receive(:perform_now)

      run_job

      expect(merge_calls).to be_empty
      expect(report.reload.pdf_file.download).to eq '%PDF-1.4 fake'
    end

    it 'skips tasks the user cannot read' do
      other_user = create(:user)
      other_team = create :team, created_by: other_user
      other_project = create :project, team: other_team, created_by: other_user
      other_experiment = create :experiment, project: other_project, created_by: other_user
      other_module = create :my_module, experiment: other_experiment, created_by: other_user,
                                        my_module_status: MyModuleStatus.first
      create :result_asset, result: create(:result, my_module: other_module, user: other_user),
                            asset: create(:asset, team: other_team)
      report.report_elements.destroy_all
      create :report_element, report: report, type_of: :my_module, my_module: other_module
      expect(PdfPreviewJob).not_to receive(:perform_now)

      run_job

      expect(merge_calls).to be_empty
    end

    it 'keeps the report unchanged when the preview pdf is encrypted' do
      asset.file_pdf_preview.attach(io: StringIO.new('%PDF preview'), filename: 'doc.pdf')
      allow(Open3).to receive(:capture3).and_return(
        ['', Reports::PdfJob::PDFUNITE_ENCRYPTED_PDF_ERROR_STRING, instance_double(Process::Status, success?: false)]
      )
      allow(Rails.logger).to receive(:warn)

      run_job

      expect(Rails.logger).to have_received(:warn).with(/Cannot merge encrypted PDF/)
      expect(report.reload.pdf_file.download).to eq '%PDF-1.4 fake'
      expect(report).to be_pdf_ready
    end

    it 'fails the report when pdfunite fails for another reason' do
      asset.file_pdf_preview.attach(io: StringIO.new('%PDF preview'), filename: 'doc.pdf')
      allow(Open3).to receive(:capture3).and_return(
        ['', 'boom', instance_double(Process::Status, success?: false)]
      )

      expect { run_job }.to raise_error(StandardError, /error merging report and PDF file preview \(boom\)/)
      expect(report.reload).to be_pdf_error
    end
  end
end
