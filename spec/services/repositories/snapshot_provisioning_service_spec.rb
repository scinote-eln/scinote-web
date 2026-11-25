# frozen_string_literal: true

require 'rails_helper'

describe Repositories::SnapshotProvisioningService do
  let(:user) { create :user }
  let(:repository) { create :repository, created_by: user }
  let(:text_column) { create :repository_column, :text_type, repository: repository, created_by: user }
  let(:my_module) { create :my_module }
  let(:repository_snapshot) { RepositorySnapshot.create_preliminary!(repository, my_module, user) }

  def create_assigned_row(name, cells = {})
    row = create :repository_row, name: name, repository: repository, created_by: user
    cells.each { |column, data| RepositoryCell.create_with_value!(row, column, data, user) }
    create :mm_repository_row, repository_row: row, my_module: my_module, assigned_by: user
    row
  end

  def provision
    described_class.call(repository_snapshot: repository_snapshot)
  end

  def snapshot_column(column)
    repository_snapshot.repository_columns.find_by!(parent_id: column.id)
  end

  def snapshot_text_values(column)
    RepositoryTextValue.joins(:repository_cell)
                       .where(repository_cells: { repository_column_id: snapshot_column(column).id })
                       .pluck(:data)
  end

  def build_text_value(data, row, column)
    RepositoryTextValue.new_with_payload(
      data,
      repository_cell: RepositoryCell.new(repository_row: row, repository_column: column),
      created_by: user, last_modified_by: user
    )
  end

  describe 'mandatory columns' do
    let!(:mandatory_column) do
      create :repository_column, :text_type, repository: repository, created_by: user, mandatory: true
    end

    before do
      text_column
      create_assigned_row('Sample A')
      create_assigned_row('Sample B', mandatory_column => 'Acme')
    end

    it 'provisions the snapshot when items have empty mandatory values' do
      service = provision

      expect(service.succeed?).to be true
      expect(repository_snapshot.reload).to be_ready
      expect(repository_snapshot.repository_rows.pluck(:name)).to contain_exactly('Sample A', 'Sample B')
      expect(snapshot_text_values(mandatory_column)).to eq(%w(Acme))
    end

    it 'keeps the mandatory flags the columns had when the snapshot was taken' do
      provision
      mandatory_column.update!(mandatory: false)
      text_column.update!(mandatory: true)

      expect(snapshot_column(mandatory_column).mandatory).to be true
      expect(snapshot_column(text_column).mandatory).to be false
    end
  end

  describe 'uniqueness' do
    context 'when the inventory already holds duplicates' do
      before do
        create_assigned_row('Sample A', text_column => 'Lot 42')
        create_assigned_row('Sample A', text_column => 'Lot 42')
        repository.update!(enforce_unique_item_names: true)
        text_column.update!(enforce_unique: true)
      end

      it 'provisions the snapshot with the duplicates copied' do
        service = provision

        expect(service.succeed?).to be true
        expect(repository_snapshot.reload).to be_ready
        expect(repository_snapshot.repository_rows.pluck(:name)).to eq(['Sample A', 'Sample A'])
        expect(snapshot_text_values(text_column)).to eq(['Lot 42', 'Lot 42'])
        expect(snapshot_column(text_column).enforce_unique?).to be true
      end
    end

    context 'when uniqueness is enforced' do
      let(:repository) { create :repository, created_by: user, enforce_unique_item_names: true }
      let(:text_column) do
        create :repository_column, :text_type, repository: repository, created_by: user, enforce_unique: true
      end
      let!(:source_row) { create_assigned_row('Sample A', text_column => 'Lot 42') }
      let(:new_row) { create :repository_row, name: 'Sample B', repository: repository, created_by: user }

      before { provision }

      it 'does not apply uniqueness to the snapshot copies' do
        expect(repository_snapshot.reload).to be_ready
        expect(repository_snapshot.repository_rows.pluck(:name)).to eq(['Sample A'])
        expect(snapshot_text_values(text_column)).to eq(['Lot 42'])
      end

      it 'still rejects duplicates of the source items' do
        expect(build(:repository_row, name: 'Sample A', repository: repository, created_by: user)).not_to be_valid
        expect(build_text_value('Lot 42', new_row, text_column)).not_to be_valid
      end

      it 'does not count the snapshot copies as existing values in the source inventory' do
        source_row.update!(name: 'Sample Z')
        source_row.repository_cells.first.value.update_data!('Lot 43', user)

        expect(build(:repository_row, name: 'Sample A', repository: repository, created_by: user)).to be_valid
        expect(build_text_value('Lot 42', new_row, text_column)).to be_valid
      end
    end
  end
end
