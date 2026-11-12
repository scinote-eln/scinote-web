# frozen_string_literal: true

require 'rails_helper'

describe ReportDatatable do
  include Rails.application.routes.url_helpers

  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user, name: 'Alpha project' }
  let(:other_project) { create :project, team: team, created_by: user, name: 'Beta project' }
  let(:modifier) { create :user, full_name: 'Mod Ifier' }

  let!(:report_a) do
    create :report, user: user, project: project, team: team, name: 'Zulu report', description: 'first one',
                    last_modified_by: modifier
  end
  let!(:report_b) do
    create :report, user: user, project: other_project, team: team, name: 'Alfa report', description: 'second one'
  end

  let(:extra_params) { {} }
  let(:order) { { '0' => { column: '1', dir: 'asc' } } }
  let(:params) do
    ActionController::Parameters.new(
      { draw: '1', start: '0', length: '10', order: order,
        columns: columns }.merge(extra_params)
    )
  end
  # column 0 is the row id and is not orderable, as in the table definition
  let(:columns) do
    (0..9).to_h { |i| [i.to_s, { data: i.to_s, orderable: (i.positive?).to_s }] }
  end
  let(:view) do
    double('view', params: params).tap do |v|
      allow(v).to receive(:edit_project_report_path) { |project_id, id| edit_project_report_path(project_id, id) }
    end
  end
  let(:reports) { Report.where(team: team) }
  let(:datatable) { described_class.new(view, user, reports) }

  def names(rows)
    rows.map { |row| row['2'] }
  end

  describe 'column configuration' do
    it 'uses the same columns for sorting and searching' do
      expect(datatable.sortable_columns).to eq described_class::TABLE_COLUMNS
      expect(datatable.searchable_columns).to eq described_class::TABLE_COLUMNS
    end
  end

  describe '#data' do
    it 'returns one row per report with escaped texts, formatted dates and action urls' do
      report_a.update!(name: '<b>Zulu</b>')
      row = datatable.send(:data).find { |r| r['0'] == report_a.id }

      expect(row).to include(
        '1' => 'Alpha project',
        '2' => CGI.escapeHTML('<b>Zulu</b>'),
        '3' => report_a.code,
        '6' => user.full_name,
        '7' => 'Mod Ifier',
        '8' => I18n.l(report_a.created_at, format: :full),
        '9' => I18n.l(report_a.reload.updated_at, format: :full),
        'archived' => false,
        'edit' => edit_project_report_path(project.id, report_a.id),
        'status' => status_project_report_path(project.id, report_a.id),
        'generate_pdf' => generate_pdf_project_report_path(project.id, report_a.id),
        'generate_docx' => generate_docx_project_report_path(project.id, report_a.id),
        'save_to_inventory' => save_pdf_to_inventory_modal_report_path(report_a.id)
      )
    end

    it 'reports an empty modifier name and an archived project' do
      project.update_column(:archived, true)
      row = datatable.send(:data).find { |r| r['0'] == report_b.id }

      expect(row).to include('7' => '', 'archived' => false)
      expect(datatable.send(:data).find { |r| r['0'] == report_a.id }['archived']).to be true
    end

    it 'describes the pdf and docx file state without preview urls while nothing is attached' do
      report_a.pdf_processing!
      report_a.docx_error!
      row = datatable.send(:data).find { |r| r['0'] == report_a.id }

      expect(row['4']).to eq(processing: true, preview_url: nil, error: false)
      expect(row['5']).to eq(processing: false, preview_url: nil, error: true)
    end

    it 'adds a preview url for an attached pdf and docx preview file' do
      report_a.pdf_file.attach(io: StringIO.new('%PDF'), filename: 'r.pdf', content_type: 'application/pdf')
      report_a.docx_preview_file.attach(io: StringIO.new('%PDF'), filename: 'r.pdf', content_type: 'application/pdf')
      row = datatable.send(:data).find { |r| r['0'] == report_a.id }

      expect(row['4'][:preview_url]).to eq document_preview_report_path(report_a, report_type: :pdf)
      expect(row['5'][:preview_url]).to eq document_preview_report_path(report_a, report_type: :docx)
    end
  end

  describe 'records' do
    it 'only contains the reports given to the datatable' do
      create :report, user: user, project: project, team: create(:team, created_by: user), name: 'Foreign'

      expect(names(datatable.send(:data))).to contain_exactly('Zulu report', 'Alfa report')
    end

    context 'when sorting' do
      %w(asc desc).each do |dir|
        context "by name #{dir}" do
          let(:order) { { '0' => { column: '2', dir: dir } } }

          it 'orders by the report name' do
            expected = %w(Alfa\ report Zulu\ report)
            expected.reverse! if dir == 'desc'
            expect(names(datatable.send(:data))).to eq expected
          end
        end
      end

      context 'by project name' do
        let(:order) { { '0' => { column: '1', dir: 'desc' } } }

        it 'orders by the project name' do
          expect(datatable.send(:data).map { |r| r['1'] }).to eq ['Beta project', 'Alpha project']
        end
      end

      context 'by code' do
        let(:order) { { '0' => { column: '3', dir: 'desc' } } }

        it 'orders by the report id' do
          expect(datatable.send(:data).map { |r| r['0'] }).to eq [report_a.id, report_b.id].sort.reverse
        end
      end

      %w(pdf docx).each do |kind|
        context "by #{kind} file" do
          let(:order_column) { kind == 'pdf' ? '4' : '5' }
          let(:dir) { 'asc' }
          let(:order) { { '0' => { column: order_column, dir: dir } } }

          before do
            report_a.public_send("#{kind}_file").attach(io: StringIO.new('x'), filename: "r.#{kind}")
          end

          context 'ascending' do
            it 'lists the report with the attachment before the one without' do
              expect(datatable.send(:data).map { |r| r['0'] }).to eq [report_a.id, report_b.id]
            end
          end

          context 'descending' do
            let(:dir) { 'desc' }

            it 'lists the report without the attachment first' do
              expect(datatable.send(:data).map { |r| r['0'] }).to eq [report_b.id, report_a.id]
            end
          end
        end
      end
    end

    context 'when searching' do
      def search(value)
        params[:search] = { value: value }
        names(described_class.new(view, user, reports).send(:data))
      end

      it 'matches the project name' do
        expect(search('Beta')).to eq ['Alfa report']
      end

      it 'matches the report name' do
        expect(search('Zulu')).to eq ['Zulu report']
      end

      it 'matches the description' do
        expect(search('second')).to eq ['Alfa report']
      end

      it 'matches the report code' do
        expect(search(report_a.code)).to eq ['Zulu report']
      end

      it 'returns nothing when nothing matches' do
        expect(search('nonexistent-thing')).to eq []
      end
    end

    context 'when paginating' do
      let(:extra_params) { { length: '1', start: '1' } }

      it 'returns only the requested page' do
        expect(names(datatable.send(:data)).size).to eq 1
      end
    end
  end
end
