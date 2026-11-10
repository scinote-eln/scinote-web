# frozen_string_literal: true

require 'rails_helper'

# Also exercises Reports::Docx::TableHelper (render_table, table_cell_alignment, add_headers_to_table)
describe Reports::Docx::DrawStepTable do
  include_context 'docx_report'

  let(:step) { add_step(name: 'Table step') }
  let(:metadata) { {} }
  let(:table) do
    create :table, name: 'Measurements', contents: { data: [%w(a b), %w(c d)] }.to_json, metadata: metadata
  end

  before { create :step_table, step: step, table: table }

  def draw(type = 'step_table')
    renderer.draw_step_table(table, type)
  end

  it 'draws the table with an index header row and column and a caption' do
    draw
    expect(table_rows).to eq([['', 'A', 'B'], %w(1 a b), %w(2 c d)])
    expect(all_text).to include(I18n.t('projects.reports.elements.step_table.table_name', name: 'Measurements'))
    expect(all_text).to include(
      I18n.t('projects.reports.elements.step_table.user_time', timestamp: I18n.l(table.created_at, format: :full))
    )
  end

  it 'styles the header row and column with the concrete background' do
    draw
    shaded = document_node.xpath("//tc[tcPr/shd/@fill='#{renderer.instance_variable_get(:@color)[:concrete]}']")
    expect(shaded.size).to eq(3 + 2)
  end

  it 'uses the well plate caption and numeric column headers for well plates' do
    draw('well_plates_table')
    expect(table_rows.first).to eq(['', '1', '2'])
    expect(table_rows.map(&:first)).to eq(['', 'A', 'B'])
    expect(all_text).to include(I18n.t('projects.reports.elements.step_well_plates_table.table_name',
                                       name: 'Measurements'))
  end

  it 'draws archive metadata for an archived table' do
    archived_on = Time.zone.local(2024, 8, 8, 8)
    table.update_columns(archived: true, archived_on: archived_on, archived_by_id: user.id)
    draw
    expect(all_text).to include(
      I18n.t('projects.reports.elements.archived_metadata', datetime: I18n.l(archived_on, format: :full),
                                                            user: user.full_name)
    )
  end

  context 'when timestamps are excluded' do
    let(:report_settings) { { exclude_timestamps: true } }

    it 'draws only the table name' do
      draw
      expect(all_text).not_to include(
        I18n.t('projects.reports.elements.step_table.user_time', timestamp: I18n.l(table.created_at, format: :full))
      )
      expect(all_text).to include(I18n.t('projects.reports.elements.step_table.table_name', name: 'Measurements'))
    end
  end

  context 'with calculated cells and alignment metadata' do
    let(:metadata) do
      { cells: [{ row: 0, col: 1, calculated: '42' }, 'not a hash', { row: nil, col: 0, calculated: 'x' }] }
    end

    it 'replaces cell contents with calculated values' do
      draw
      expect(table_rows[1]).to eq(%w(1 a 42))
    end
  end

  context 'with an empty table' do
    let(:table) { create :table, name: 'Empty', contents: { data: [] }.to_json }

    it 'draws only the caption' do
      draw
      expect(document_node.xpath('//tbl')).to be_empty
      expect(all_text).to include('Empty')
    end
  end

  describe '#table_cell_alignment' do
    {
      'htCenter htMiddle' => :center,
      'htRight' => :right,
      'htJustify' => :both,
      'htLeft' => :left,
      '' => :left
    }.each do |css, expected|
      it "maps '#{css}' to #{expected}" do
        expect(renderer.table_cell_alignment(css)).to eq(expected)
      end
    end
  end

  describe '#convert_index_to_letter' do
    it 'converts indexes to spreadsheet column names' do
      expect([0, 25, 26, 27, 701, 702].map { |i| renderer.convert_index_to_letter(i) })
        .to eq(%w(A Z AA AB ZZ AAA))
    end
  end

  describe '#add_headers_to_table' do
    it 'adds an index column and a header row' do
      expect(renderer.add_headers_to_table([%w(x y)], false)).to eq([['', 'A', 'B'], [1, 'x', 'y']])
    end
  end
end
