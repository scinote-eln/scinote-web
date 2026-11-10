# frozen_string_literal: true

require 'rails_helper'

# Also exercises Reports::Docx::RepositoryHelper (prepare_row_columns_for_docx)
describe Reports::Docx::DrawMyModuleRepository do
  include_context 'docx_report'

  let(:repository) { create :repository, team: team, created_by: user, name: 'Samples inventory' }
  let!(:row) do
    create(:repository_row, repository: repository, created_by: user, name: 'Sample row').tap do |r|
      create :mm_repository_row, repository_row: r, my_module: my_module, assigned_by: user
    end
  end
  let(:element) do
    create :report_element, report: report, type_of: :my_module_repository, my_module: my_module,
                            repository: repository
  end

  def draw
    renderer.draw_my_module_repository(element)
  end

  def add_text_cell(target_row, column, value)
    cell = create :repository_cell, :text_value, repository_row: target_row, repository_column: column
    cell.value.update!(data: value)
  end

  it 'draws the caption and a table with default columns and one line per assigned row' do
    draw
    expect(all_text).to include(
      I18n.t('projects.reports.elements.module_repository.name', repository: 'Samples inventory',
                                                                  my_module: my_module.name)
    )
    header, data = table_rows
    expect(header).to eq(Report.default_repository_columns.values)
    expect(data.map(&:strip)).to include(row.code, 'Sample row', user.full_name)
    expect(data).to include(I18n.l(row.created_at, format: :full))
  end

  it 'draws only rows assigned to the task' do
    other = create :repository_row, repository: repository, created_by: user, name: 'Unassigned row'
    draw
    expect(table_rows.flatten.map(&:strip)).not_to include(other.name)
    expect(table_rows.size).to eq(2)
  end

  it 'draws custom column values after the default columns' do
    column = create :repository_column, repository: repository, created_by: user, name: 'Notes'
    add_text_cell(row, column, 'custom note')
    draw
    header, data = table_rows
    expect(header.last).to eq('Notes')
    expect(data.last).to eq('custom note')
  end

  it 'marks archived rows' do
    row.update_columns(archived: true, archived_on: Time.zone.now, archived_by_id: user.id)
    draw
    expect(table_rows.flatten.map(&:strip)).to include("Sample row [#{I18n.t('general.archived')}]")
  end

  it 'marks output rows produced by this task' do
    row.update_columns(my_module_id: my_module.id)
    draw
    expect(table_rows.flatten.map(&:strip)).to include("Sample row [#{I18n.t('general.output')}]")
  end

  it 'escapes html in the row name' do
    row.update_columns(name: '<b>bold</b>')
    draw
    expect(table_rows.flatten.join).to include('&lt;b&gt;bold&lt;/b&gt;')
  end

  context 'with excluded columns' do
    let(:report_settings) do
      { task: { excluded_repository_columns: { repository.id.to_s => [-1, -3, -4] } } }
    end

    it 'leaves out the excluded default columns in header and rows' do
      draw
      header, data = table_rows
      expect(header).to eq([Report.default_repository_columns[:'-2']])
      expect(data.map(&:strip)).to eq(['Sample row'])
    end
  end

  context 'when every column is excluded' do
    let(:report_settings) do
      { task: { excluded_repository_columns: { repository.id.to_s => [-1, -2, -3, -4] } } }
    end

    it 'draws the no columns note instead of a table' do
      draw
      expect(all_text).to include(I18n.t('projects.reports.elements.module_repository.no_columns'))
      expect(document_node.xpath('//tbl')).to be_empty
    end
  end

  it 'draws nothing when the repository is not assigned to the task' do
    other_repository = create :repository, team: team, created_by: user
    other_element = create :report_element, report: report, type_of: :my_module_repository, my_module: my_module,
                                            repository: other_repository

    expect(renderer.draw_my_module_repository(other_element)).to be_nil
    expect(document_node.xpath('//tbl')).to be_empty
    expect(all_text).not_to include(other_repository.name)
  end

  context 'with a selected repository snapshot' do
    it 'draws the snapshot name and its assigned rows' do
      snapshot = create :repository_snapshot, original_repository: repository, my_module: my_module, selected: true,
                                              created_by: user
      snapshot_row = create(:repository_row, repository: snapshot, created_by: user, name: 'Snapshot row')
      create :mm_repository_row, repository_row: snapshot_row, my_module: my_module, assigned_by: user
      draw
      expect(table_rows.flatten.map(&:strip)).to include('Snapshot row')
      expect(table_rows.flatten.map(&:strip)).not_to include('Sample row')
    end
  end
end
