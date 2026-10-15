# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MyModuleReports::MergePdfsWithWatermarkService do
  include_context 'docx_report'

  let(:step) { add_step(name: 'Step with files') }
  let(:result) { create :result, my_module: my_module, user: user, name: 'Result with files' }
  let(:report_template) { ReportTemplate.create!(subject: my_module, name: 'Template') }
  let(:analytical_report) do
    AnalyticalReport.create!(name: 'Analytical', generating_status: :in_progress, reference: my_module,
                             created_by: user, report_template: report_template).tap do |ar|
      ar.report.attach(io: StringIO.new('%PDF-1.4 REPORT'), filename: 'generated.pdf', content_type: 'application/pdf')
    end
  end
  let(:header_text) { nil }
  let(:footer_text) { nil }
  let(:numbering) { false }
  let(:blank_page) { false }
  let(:acting_user) { user }
  let(:asset_ids) { [asset_a.id, asset_b.id] }
  let(:commands) { [] }
  let(:united) { [] }
  let(:watermark_files) { [] }
  let(:odt_fields) { [] }
  let(:pdfinfo_output) { "Pages:          2\nPage size:      595.276 x 841.89 pts (A4)\n" }
  let(:pdfinfo_code) { 0 }
  let(:unite_stderr) { '' }
  let(:unite_code) { 0 }
  let(:unite_writes_output) { true }
  let(:qpdf_code) { 0 }
  let(:qpdf_writes_output) { true }

  def status(code)
    double('status', success?: code.zero?, exitstatus: code)
  end

  def pdf_asset(parent, content, name)
    asset = if parent.is_a?(Step)
              create(:step_asset, step: parent).asset
            else
              create(:result_asset, result: parent).asset
            end
    asset.file.attach(io: StringIO.new("%PDF-1.4 #{content}"), filename: name, content_type: 'application/pdf')
    asset
  end

  let!(:asset_a) { pdf_asset(step, 'A', 'a.pdf') }
  let!(:asset_b) { pdf_asset(result, 'B', 'b.pdf') }

  def service(ids = asset_ids)
    described_class.new(acting_user, analytical_report, ids, header_text, footer_text, numbering, blank_page)
  end

  def label(path)
    path.to_s.end_with?('empty_page.pdf') ? 'BLANK' : File.read(path).delete_prefix('%PDF-1.4 ')
  end

  before do
    user.update!(current_team_id: team.id)

    # The poppler / qpdf binaries are replaced by fakes that write readable "documents": merging joins the labels
    # of its inputs with "|", overlaying wraps the labels in overlay(...)
    allow(Open3).to receive(:capture3) do |*cmd|
      commands << cmd
      case cmd.first
      when 'pdfinfo'
        [pdfinfo_output, 'pdfinfo error', status(pdfinfo_code)]
      when 'pdfunite'
        united << cmd[1..-2].map { |path| label(path) }
        File.write(cmd.last, united.last.join('|')) if unite_writes_output
        ['', unite_stderr, status(unite_code)]
      when 'qpdf'
        File.write(cmd.last, "overlay(#{label(cmd[1])},#{label(cmd[3])})") if qpdf_writes_output
        ['', 'qpdf warning', status(qpdf_code)]
      end
    end

    allow(Reports::ConvertFileFormatService).to receive(:convert_batch) do |odt_files, format|
      expect(format).to eq 'pdf'
      expect(odt_files).to all(respond_to(:path))
      odt_files.each_with_index.map do |_odt, index|
        Tempfile.new(['wm', '.pdf']).tap do |file|
          file.write("WM#{index + 1}")
          file.flush
          watermark_files << file
        end.path
      end
    end

    allow_any_instance_of(ODFReport::Report).to receive(:add_field).and_wrap_original do |original, *args|
      odt_fields << args
      original.call(*args)
    end
  end

  after { watermark_files.each(&:close!) }

  def attached_content
    analytical_report.reload.report.download
  end

  def commands_named(name)
    commands.select { |cmd| cmd.first == name }
  end

  describe 'merging without watermark' do
    it 'merges the pdf assets after the report and re-attaches the result under the original name' do
      service.generate!

      expect(attached_content).to eq 'REPORT|A|B'
      expect(analytical_report.report.filename.to_s).to eq 'generated.pdf'
      expect(commands_named('qpdf')).to be_empty
      expect(Reports::ConvertFileFormatService).not_to have_received(:convert_batch)
    end

    it 'follows the order of the given asset ids' do
      service([asset_b.id, asset_a.id]).generate!
      expect(attached_content).to eq 'REPORT|B|A'
    end

    it 'ignores ids that are not active pdfs of an active step or result of the task' do
      image_asset = create(:step_asset, step: step).asset
      archived_step = add_step(name: 'Archived')
      archived_step_asset = pdf_asset(archived_step, 'X', 'x.pdf')
      archived_step.update!(archived: true, archived_on: Time.current)
      archived_asset = pdf_asset(step, 'Y', 'y.pdf')
      archived_asset.update_columns(archived: true)
      other_task = create :my_module, experiment: experiment, created_by: user, name: 'Other'
      foreign_asset = pdf_asset(add_step(protocol: other_task.protocol, name: 'Other step'), 'Z', 'z.pdf')

      ids = [asset_a.id, image_asset.id, archived_step_asset.id, archived_asset.id, foreign_asset.id, asset_b.id]
      service(ids).generate!

      expect(attached_content).to eq 'REPORT|A|B'
    end

    it 'leaves the report unchanged when no asset is requested' do
      service([]).generate!
      expect(attached_content).to eq '%PDF-1.4 REPORT'
      expect(commands).to be_empty
    end

    context 'when the user cannot read the assets' do
      let(:acting_user) { create(:user).tap { |u| u.update!(current_team_id: team.id) } }

      it 'does not merge them' do
        service.generate!
        expect(attached_content).to eq '%PDF-1.4 REPORT'
        expect(commands_named('pdfinfo')).to be_empty
      end
    end

    it 'cleans up all temporary files' do
      instance = service
      instance.generate!
      tempfiles = instance.instance_variable_get(:@tempfiles)
      expect(tempfiles).not_to be_empty
      expect(tempfiles.map(&:path)).to all(be_nil)
    end

    context 'when an encrypted pdf cannot be merged' do
      let(:unite_stderr) { described_class::PDFUNITE_ENCRYPTED_PDF_ERROR_STRING }

      it 'warns and keeps the report as it is' do
        allow(Rails.logger).to receive(:warn)
        service.generate!
        expect(Rails.logger).to have_received(:warn).with('Cannot merge encrypted PDF, skipping!').twice
        expect(attached_content).to eq '%PDF-1.4 REPORT'
      end
    end

    context 'when pdfunite fails' do
      let(:unite_code) { 1 }
      let(:unite_stderr) { 'bad pdf' }

      it 'raises with the asset id and cleans up' do
        instance = service
        expect { instance.generate! }.to raise_error(
          StandardError, "There was an error merging report and PDF file preview (bad pdf) (asset_id: #{asset_a.id})"
        )
        expect(instance.instance_variable_get(:@tempfiles).map(&:path)).to all(be_nil)
        expect(attached_content).to eq '%PDF-1.4 REPORT'
      end
    end

    context 'when pdfunite produces no output' do
      let(:unite_writes_output) { false }

      it 'raises' do
        expect { service.generate! }.to raise_error(StandardError, /error merging report and PDF file preview/)
      end
    end
  end

  describe 'pdfinfo parsing' do
    context 'when pdfinfo fails' do
      let(:pdfinfo_code) { 1 }

      it 'raises with the pdfinfo message and the asset id' do
        expect { service.generate! }.to raise_error(StandardError, "pdfinfo failed: pdfinfo error (asset_id: #{asset_a.id})")
      end
    end

    context 'when the page count is missing' do
      let(:pdfinfo_output) { "Page size: 595 x 842 pts (A4)\n" }

      it 'raises a parse error' do
        expect { service.generate! }.to raise_error(StandardError, /Could not parse page count: nil/)
      end
    end

    context 'when the page size is missing' do
      let(:pdfinfo_output) { "Pages: 1\n" }

      it 'raises a parse error' do
        expect { service.generate! }.to raise_error(StandardError, /Could not parse page size:/)
      end
    end

    context 'when a command is not installed' do
      it 'raises a readable error' do
        allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)
        expect { service.generate! }.to raise_error(StandardError, /Required command not found: pdfinfo/)
      end
    end

    context 'with a blank page' do
      let(:blank_page) { true }

      {
        'A4 portrait by label' => ["Pages: 1\nPage size: 595 x 842 pts (A4)\n", 'A4_portrait'],
        'A4 landscape by label' => ["Pages: 1\nPage size: 842 x 595 pts (A4, landscape)\n", 'A4_landscape'],
        'letter portrait by label' => ["Pages: 1\nPage size: 612 x 792 pts (letter, portrait)\n", 'letter_portrait'],
        'landscape by width and height' => ["Pages: 1\nPage size: 800 x 400 pts\n", 'A4_landscape'],
        'portrait by width and height' => ["Pages: 1\nPage size: 400 x 800 pts\n", 'A4_portrait'],
        'custom formats fall back to A4' => ["Pages: 1\nPage size: 400 x 800 pts (legal)\n", 'A4_portrait']
      }.each do |name, (output, template)|
        context "with #{name}" do
          let(:pdfinfo_output) { output }
          let(:asset_ids) { [asset_a.id] }

          it "appends the #{template} empty page" do
            service.generate!
            blank_path = commands_named('pdfunite').first[2]
            expect(blank_path).to end_with("#{template}_empty_page.pdf")
            expect(attached_content).to eq 'REPORT|A|BLANK'
          end
        end
      end
    end
  end

  describe 'watermark' do
    let(:asset_ids) { [asset_a.id] }
    let(:footer_texts) { odt_fields.select { |name, _| name == :REPORT_FOOTER }.map(&:last) }
    let(:header_texts) { odt_fields.select { |name, _| name == :REPORT_HEADER }.map(&:last) }

    context 'with header and footer text' do
      let(:header_text) { 'Confidential' }
      let(:footer_text) { 'Lab' }

      it 'renders one watermark page per pdf page and overlays the merged watermark on the asset' do
        service.generate!

        expect(header_texts).to eq %w(Confidential Confidential)
        expect(footer_texts).to eq %w(Lab Lab)
        expect(Reports::ConvertFileFormatService).to have_received(:convert_batch).once
        expect(united.first).to eq %w(WM1 WM2)
        qpdf = commands_named('qpdf').first
        expect(qpdf[2]).to eq '--overlay'
        expect(qpdf[4]).to eq '--'
        expect(attached_content).to eq 'REPORT|overlay(A,WM1|WM2)'
      end
    end

    context 'with page numbering' do
      let(:numbering) { true }

      it 'uses the page index as the footer' do
        service.generate!
        expect(footer_texts).to eq %w(1 2)
        expect(header_texts).to eq [nil, nil]
      end
    end

    context 'with numbering and footer text' do
      let(:numbering) { true }
      let(:footer_text) { 'Lab' }

      it 'appends the page index to the footer text' do
        service.generate!
        expect(footer_texts).to eq %w(Lab_1 Lab_2)
      end
    end

    context 'with only a header' do
      let(:header_text) { 'Top secret' }

      it 'renders the header without footer' do
        service.generate!
        expect(header_texts).to eq ['Top secret', 'Top secret']
        expect(footer_texts).to eq [nil, nil]
      end
    end

    context 'with a single page pdf' do
      let(:footer_text) { 'Only' }
      let(:pdfinfo_output) { "Pages: 1\nPage size: 612 x 792 pts (letter)\n" }

      it 'does not need to merge the watermark pages' do
        service.generate!
        expect(united).to eq [['REPORT', 'overlay(A,WM1)']]
        expect(attached_content).to eq 'REPORT|overlay(A,WM1)'
      end
    end

    context 'with a blank page and header' do
      let(:blank_page) { true }
      let(:header_text) { 'H' }

      it 'counts the blank page in the watermark and overlays the merged content' do
        service.generate!
        expect(header_texts.size).to eq 3
        expect(attached_content).to eq 'REPORT|overlay(A|BLANK,WM1|WM2|WM3)'
      end
    end

    context 'when qpdf only warns (exit code 3)' do
      let(:header_text) { 'H' }
      let(:qpdf_code) { 3 }

      it 'accepts the output' do
        service.generate!
        expect(attached_content).to eq 'REPORT|overlay(A,WM1|WM2)'
      end
    end

    context 'when qpdf fails' do
      let(:header_text) { 'H' }
      let(:qpdf_code) { 2 }

      it 'raises with the qpdf message' do
        expect { service.generate! }.to raise_error(StandardError, /qpdf overlay failed: qpdf warning \(asset_id: #{asset_a.id}\)/)
      end
    end

    context 'when qpdf produces no output' do
      let(:header_text) { 'H' }
      let(:qpdf_writes_output) { false }

      it 'raises' do
        expect { service.generate! }.to raise_error(StandardError, /qpdf overlay produced no output/)
      end
    end
  end
end
