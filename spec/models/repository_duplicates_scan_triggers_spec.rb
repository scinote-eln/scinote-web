# frozen_string_literal: true

require 'rails_helper'

describe 'Inventory duplicates scan triggers' do
  around do |example|
    queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = queue_adapter
  end

  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user }
  let(:column) { create :repository_column, :text_type, repository: repository, created_by: user }
  let!(:row) { create :repository_row, repository: repository, name: 'Sample', created_by: user, last_modified_by: user }

  it 'scans when uniqueness is turned on for the Name column' do
    expect { repository.update!(enforce_unique_item_names: true) }.to have_enqueued_job(RepositoryDuplicatesScanJob)
  end

  it 'scans when uniqueness is turned on for a Text column' do
    expect { column.update!(enforce_unique: true) }.to have_enqueued_job(RepositoryDuplicatesScanJob)
  end

  it 'does not scan on unrelated column changes' do
    expect { column.update!(name: 'Renamed') }.not_to have_enqueued_job(RepositoryDuplicatesScanJob)
  end

  it 'does not touch flags when an item that is not a duplicate is renamed' do
    expect { row.update!(name: 'Fixed') }.not_to(change { row.reload.duplicated })
  end

  context 'when items are flagged as duplicated' do
    let!(:twin) { create :repository_row, repository: repository, name: 'sample', created_by: user, last_modified_by: user }

    before do
      repository.update_columns(enforce_unique_item_names: true)
      RepositoryRow.where(id: [row.id, twin.id]).update_all(duplicated: true)
      repository.update_columns(duplicated_items_count: 2)
      row.reload
    end

    it 'unflags the item and its former duplicate once it is renamed, without a rescan' do
      expect { row.update!(name: 'Fixed') }.not_to have_enqueued_job(RepositoryDuplicatesScanJob)

      expect(repository.repository_rows.where(duplicated: true)).to be_empty
      expect(repository.reload.duplicated_items_count).to eq(0)
    end

    it 'keeps the other items flagged while they still collide with each other' do
      third = build :repository_row, repository: repository, name: 'SAMPLE', created_by: user, last_modified_by: user,
                                     duplicated: true
      third.save!(validate: false)

      row.update!(name: 'Fixed')

      expect(repository.repository_rows.where(duplicated: true)).to contain_exactly(twin, third)
      expect(repository.reload.duplicated_items_count).to eq(2)
    end

    it 'keeps the flags while the items still collide in another column' do
      cell = RepositoryCell.create_with_value!(row, column, 'Lot 42', user)
      RepositoryCell.create_with_value!(twin, column, 'Lot 42', user)
      column.update_columns(metadata: { enforce_unique: true })

      cell.value.update!(data: 'Lot 43')

      expect(repository.repository_rows.where(duplicated: true)).to contain_exactly(row, twin)
    end

    it 'unflags both items once their unique text values no longer collide' do
      repository.update_columns(enforce_unique_item_names: false)
      cell = RepositoryCell.create_with_value!(row, column, 'Lot 42', user)
      RepositoryCell.create_with_value!(twin, column, 'Lot 42', user)
      column.update_columns(metadata: { enforce_unique: true })

      cell.value.update!(data: 'Lot 43')

      expect(repository.repository_rows.where(duplicated: true)).to be_empty
      expect(repository.reload.duplicated_items_count).to eq(0)
    end

    it 'unflags both items when the unique text value of one is deleted' do
      repository.update_columns(enforce_unique_item_names: false)
      cell = RepositoryCell.create_with_value!(row, column, 'Lot 42', user)
      RepositoryCell.create_with_value!(twin, column, 'Lot 42', user)
      column.update_columns(metadata: { enforce_unique: true })

      cell.value.destroy!

      expect(repository.repository_rows.where(duplicated: true)).to be_empty
      expect(repository.reload.duplicated_items_count).to eq(0)
    end

    it 'unflags both items when one is archived' do
      row.archive!(user)

      expect(repository.repository_rows.where(duplicated: true)).to be_empty
      expect(repository.reload.duplicated_items_count).to eq(0)
    end

    it 'unflags the other item when one is deleted' do
      RepositoryCell.create_with_value!(row, column, 'Lot 42', user)

      row.destroy!

      expect(twin.reload.duplicated).to be(false)
      expect(repository.reload.duplicated_items_count).to eq(0)
    end
  end
end
