# frozen_string_literal: true

require 'rails_helper'

describe FormRepositoryRowsFieldValue, type: :model do
  let!(:repository) { create :repository }
  let!(:repository_row_1) { create :repository_row, repository: repository }
  let!(:repository_row_2) { create :repository_row, repository: repository }
  let!(:repository_row_3) { create :repository_row, repository: repository }

  let(:form) { create :form }
  let(:form_field) { create :form_field, form: form, data: { type: 'FormRepositoryRowsFieldValue', validations: {} } }
  let(:form_field_value) { (create :form_field_value, type: 'FormRepositoryRowsFieldValue').becomes(FormRepositoryRowsFieldValue) }

  it 'adds new repository row snapshots' do
    form_field_value.update(value: [repository_row_1.id, repository_row_2.id])
    expect(form_field_value.data.pluck('id')).to eq [repository_row_1.id, repository_row_2.id]
    expect(form_field_value.data[0]['snapshot_by_id']).to eq form_field_value.created_by_id
  end

  it 'removes repository row snapshots' do
    form_field_value.update(value: [repository_row_1.id, repository_row_2.id, repository_row_3.id])
    expect(form_field_value.data.pluck('id')).to eq [repository_row_1.id, repository_row_2.id, repository_row_3.id]

    form_field_value.update(value: [repository_row_1.id, repository_row_2.id])
    expect(form_field_value.data.pluck('id')).to eq [repository_row_1.id, repository_row_2.id]
  end

  it 'keeps existing repository row snapshots intact' do
    form_field_value.update(value: [repository_row_1.id, repository_row_2.id])

    existing_snapshot_timestamp = form_field_value.data[0]['snapshot_at']
    existing_snapshot_name = form_field_value.data[0]['name']

    repository_row_1.update(name: "New name!")

    form_field_value.update(value: [repository_row_1.id, repository_row_2.id, repository_row_3.id])
    expect(form_field_value.data.pluck('id')).to eq [repository_row_1.id, repository_row_2.id, repository_row_3.id]

    expect(form_field_value.data[0]['snapshot_at']).to eq existing_snapshot_timestamp
    expect(form_field_value.data[0]['name']).to eq existing_snapshot_name
  end
  describe 'snapshots with cells' do
    let(:user) { create :user }
    let(:row) { create :repository_row, repository: repository, created_by: user, last_modified_by: user }

    def create_asset_cell
      cell = create :repository_cell, :asset_value, repository_row: row
      cell.value.asset.file.attach(io: File.open(Rails.root.join('spec/fixtures/files/test.jpg')),
                                   filename: 'test.jpg')
      cell
    end

    def snapshot_value(*rows)
      form_field_value.update!(latest: false, value: rows.map(&:id))
      form_field_value.reload
    end

    it 'stores cells including column and value data' do
      create :repository_cell, :text_value, repository_row: row
      snapshot = snapshot_value(row)
      cells = snapshot.data.first['repository_cells']
      expect(cells.length).to eq 1
      expect(cells.first['repository_column']['data_type']).to eq 'RepositoryTextValue'
      expect(cells.first['value']['data']).to be_present
    end

    it 'does not touch snapshots when called with an unknown row id' do
      snapshot = snapshot_value(row)
      snapshot.update!(latest: false, value: [row.id, -1])
      expect(snapshot.data.pluck('id')).to eq [row.id]
    end

    it 'nullifies data when the value is blank' do
      snapshot = snapshot_value(row)
      snapshot.update!(latest: false, value: [])
      expect(snapshot.reload.data).to be_nil
      expect(snapshot.value).to be_nil
      expect(snapshot.formatted).to be_nil
    end

    it 'formats the snapshots with names and ids' do
      row.update!(name: 'Formatted row')
      other = create :repository_row, repository: repository, name: 'Second row'
      snapshot = snapshot_value(row, other)
      expect(snapshot.formatted)
        .to eq "Formatted row (#{RepositoryRow::ID_PREFIX}#{row.id}) | Second row (#{RepositoryRow::ID_PREFIX}#{other.id})"
    end

    describe '#reified_repository_row_by_id' do
      it 'rebuilds a read only row with text cells' do
        create :repository_cell, :text_value, repository_row: row
        snapshot = snapshot_value(row)
        reified = snapshot.reified_repository_row_by_id(row.id)
        expect(reified).to be_readonly
        expect(reified.name).to eq row.name
        expect(reified.snapshot_by_name).to eq snapshot.created_by.full_name
        cell = reified.repository_cells.first
        expect(cell).to be_readonly
        expect(cell.value).to be_a(RepositoryTextValue)
        expect(cell.value.data).to eq row.repository_cells.first.value.data
        expect(cell.repository_column).to be_readonly
      end

      it 'rebuilds list values and list items' do
        cell = create :repository_cell, :list_value, repository_row: row
        reified = snapshot_value(row).reified_repository_row_by_id(row.id)
        value = reified.repository_cells.first.value
        expect(value).to be_a(RepositoryListValue)
        expect(value.repository_list_item.data).to eq cell.value.repository_list_item.data
        expect(value.repository_list_item).to be_readonly
      end

      it 'rebuilds status values and status items' do
        cell = create :repository_cell, :status_value, repository_row: row
        reified = snapshot_value(row).reified_repository_row_by_id(row.id)
        value = reified.repository_cells.first.value
        expect(value).to be_a(RepositoryStatusValue)
        expect(value.repository_status_item.status).to eq cell.value.repository_status_item.status
      end

      it 'rebuilds checklist values with their items' do
        column = create :repository_column, :checklist_type, repository: repository
        item = create :repository_checklist_item, repository_column: column
        create :repository_checklist_value, repository_checklist_items: [item],
                                            repository_cell_attributes: { repository_row: row,
                                                                          repository_column: column }
        reified = snapshot_value(row).reified_repository_row_by_id(row.id)
        value = reified.repository_cells.first.value
        expect(value).to be_a(RepositoryChecklistValue)
        expect(value.repository_checklist_items.map(&:id)).to eq [item.id]
        expect(value.repository_checklist_items.first).to be_readonly
      end

      it 'rebuilds asset values using the attached snapshot files' do
        cell = create_asset_cell
        snapshot = snapshot_value(row)
        expect(snapshot.snapshot_files.map(&:blob)).to eq [cell.value.asset.file.blob]
        reified = snapshot.reified_repository_row_by_id(row.id)
        asset = reified.repository_cells.first.value.asset
        expect(asset).to be_readonly
        expect(asset.file.blob).to eq cell.value.asset.file.blob
      end

      it 'does not attach the same snapshot file twice' do
        create_asset_cell
        snapshot = snapshot_value(row)
        snapshot.save!
        expect(snapshot.reload.snapshot_files.count).to eq 1
      end

      it 'rebuilds stock values reading the row from memory' do
        create :repository_cell, :stock_value, repository_row: row
        reified = snapshot_value(row).reified_repository_row_by_id(row.id)
        value = reified.repository_cells.first.value
        expect(value).to be_a(RepositoryStockValue)
        expect(value.repository_row).to eq reified
      end

      it 'raises when the row is not part of the snapshot' do
        expect { snapshot_value(row).reified_repository_row_by_id(-1) }.to raise_error(NoMethodError)
      end
    end
  end
end
