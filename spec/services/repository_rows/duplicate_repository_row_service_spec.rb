# frozen_string_literal: true

require 'rails_helper'

describe RepositoryRows::DuplicateRepositoryRowService do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let!(:column) { create :repository_column, :text_type, repository: repository }
  let!(:date_column) { create :repository_column, :date_type, repository: repository }
  let(:source_row) { create :repository_row, name: 'Original', repository: repository, created_by: user }
  let!(:source_text) { RepositoryCell.create_with_value!(source_row, column, 'original text', user) }
  let!(:source_date) { RepositoryCell.create_with_value!(source_row, date_column, '2026-11-11', user) }
  let(:params) { { repository_row: { name: 'Original (1)' } } }
  let(:service_call) do
    described_class.call(repository: repository, source_row: source_row, user: user, params: params)
  end
  let(:new_values) do
    service_call.repository_row.repository_cells.index_by(&:repository_column_id).transform_values(&:value)
  end

  context 'when no values were changed' do
    it 'copies the values of the original item' do
      expect(service_call.succeed?).to be true
      expect(service_call.repository_row.name).to eq('Original (1)')
      expect(new_values[column.id].data).to eq('original text')
      expect(new_values[date_column.id].data.to_date).to eq(Date.new(2026, 11, 11))
    end

    it 'keeps the original item values' do
      service_call

      expect(source_row.reload.repository_cells.count).to eq(2)
    end
  end

  context 'when values were changed or cleared' do
    let(:params) do
      { repository_row: { name: 'Original (1)' },
        repository_cells: { column.id.to_s => 'changed text', date_column.id.to_s => nil } }
    end

    it 'uses the changed values and does not copy the cleared ones' do
      expect(service_call.succeed?).to be true
      expect(new_values[column.id].data).to eq('changed text')
      expect(new_values).not_to have_key(date_column.id)
    end
  end

  context 'when a mandatory value is only on the original item' do
    before { column.update!(mandatory: true) }

    it 'counts the copied value' do
      expect(service_call.succeed?).to be true
    end

    context 'when it was cleared' do
      let(:params) { { repository_row: { name: 'Original (1)' }, repository_cells: { column.id.to_s => nil } } }

      it 'returns the mandatory cell error and creates nothing' do
        expect { service_call }.not_to(change(RepositoryRow, :count))
        expect(service_call.errors[:repository_cells]).to be_present
      end
    end
  end

  context 'when a copied value must be unique' do
    before { column.update!(enforce_unique: true) }

    it 'returns the unique cell error and creates nothing' do
      expect { service_call }.not_to(change(RepositoryRow, :count))
      expect(service_call.errors[:unique_cells]).to eq(column.id => ['An item with this value already exists'])
    end
  end

  context 'when the name is taken in a repository with unique names' do
    before { repository.update!(enforce_unique_item_names: true) }

    let(:params) { { repository_row: { name: 'original' } } }

    it 'returns the name error and creates nothing' do
      expect { service_call }.not_to(change(RepositoryRow, :count))
      expect(service_call.errors[:name]).to eq(['An item with this name already exists'])
    end
  end
end
