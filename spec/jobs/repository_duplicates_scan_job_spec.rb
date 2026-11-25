# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDuplicatesScanJob do
  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user }
  let(:column) { create :repository_column, :text_type, repository: repository, created_by: user }

  def create_row(name, **attrs)
    create :repository_row, repository: repository, name: name, created_by: user, last_modified_by: user, **attrs
  end

  let!(:first) { create_row('Sample') }
  let!(:second) { create_row('sample') }
  let!(:third) { create_row('Other') }
  let!(:unique) { create_row('Unique', duplicated: true) }

  before do
    RepositoryCell.create_with_value!(first, column, 'Lot 42', user)
    RepositoryCell.create_with_value!(third, column, 'Lot 42', user)
    repository.update_columns(enforce_unique_item_names: true)
    column.update_columns(metadata: { enforce_unique: true })
  end

  it 'flags duplicated items and stores their count; items duplicated in several columns count once' do
    described_class.perform_now(repository.id)

    expect(repository.repository_rows.where(duplicated: true)).to contain_exactly(first, second, third)
    expect(repository.reload.duplicated_items_count).to eq(3)
  end

  it 'clears flags and count once duplicates are resolved' do
    described_class.perform_now(repository.id)
    repository.update_columns(enforce_unique_item_names: false)
    column.update_columns(metadata: {})

    described_class.perform_now(repository.id)

    expect(repository.repository_rows.where(duplicated: true)).to be_empty
    expect(repository.reload.duplicated_items_count).to eq(0)
  end

  describe '.schedule' do
    around do |example|
      queue_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :test
      example.run
    ensure
      ActiveJob::Base.queue_adapter = queue_adapter
    end

    it 'enqueues a scan' do
      expect { described_class.schedule(repository.id) }.to have_enqueued_job(described_class).with(repository.id)
    end

    it 'does nothing when inventory integrity is disabled' do
      allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(false)

      expect { described_class.schedule(repository.id) }.not_to have_enqueued_job(described_class)
    end
  end
end
