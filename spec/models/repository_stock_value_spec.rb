# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStockValue, type: :model do
  let(:user) { build :user }
  let(:repository) { build :repository }
  let(:repository_stock_value) { build :repository_stock_value }


  it 'is valid' do
    expect(repository_stock_value).to be_valid
  end

  it 'should be of class RepositoryStockValue' do
    expect(subject.class).to eq RepositoryStockValue
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :amount }
    it { should have_db_column :repository_stock_unit_item_id }
    it { should have_db_column :type }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :low_stock_threshold }
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:repository_stock_unit_item).optional }
    it { is_expected.to belong_to(:created_by).optional }
    it { is_expected.to belong_to(:last_modified_by).optional }
  end


  describe 'Saving stock value' do
    it 'Save stock value' do
      expect { repository_stock_value.save }.to change(RepositoryStockValue, :count).by(1)
    end

    it 'Updating stock value' do
      repository_stock_unit_item =
        create :repository_stock_unit_item, repository_column: repository_stock_value.repository_cell.repository_column
      repository_stock_value.repository_cell.repository_column.reload
      repository_stock_value.save
      expect { repository_stock_value.update_data!(
        { amount: 10, low_stock_threshold: '', unit_item_id: repository_stock_unit_item.id }, user
      ) }
      .to change(RepositoryStockValue, :count).by(0)
    end

    it 'Updating stock value with ledger' do
      repository_stock_unit_item =
        create :repository_stock_unit_item, repository_column: repository_stock_value.repository_cell.repository_column
      repository_stock_unit_item.save
      repository_stock_value.repository_stock_unit_item = repository_stock_unit_item
      expect { repository_stock_value.save }.to (change(RepositoryLedgerRecord, :count).by(1))
    end
  end

  describe 'with a persisted cell' do
    let(:cell) { create :repository_cell, :stock_value }
    let(:column) { cell.repository_column }
    let(:value) { cell.value }
    let(:acting_user) { create :user }

    before { column.update!(metadata: { 'decimals' => 2 }) }

    describe '#status' do
      it 'is :empty at zero or below' do
        value.amount = 0
        expect(value.status).to eq :empty
      end

      it 'is :low at or below the threshold' do
        value.assign_attributes(amount: 5, low_stock_threshold: 5)
        expect(value.status).to eq :low
      end

      it 'is :normal above the threshold or without one' do
        value.assign_attributes(amount: 6, low_stock_threshold: 5)
        expect(value.status).to eq :normal
        value.low_stock_threshold = nil
        expect(value.status).to eq :normal
      end
    end

    describe 'formatting' do
      it 'formats amount with column decimals, unit and threshold' do
        unit = create :repository_stock_unit_item, repository_column: column, data: 'ml'
        value.assign_attributes(amount: 12.5, low_stock_threshold: 3, repository_stock_unit_item: unit)
        expect(value.formatted_value).to eq '12.5'
        expect(value.formatted).to eq '12.5 ml'
        expect(value.formatted_treshold).to eq '3'
        expect(value.export_formatted).to eq value.formatted
        expect(value.data).to eq value.amount
      end

      it 'returns nil threshold without one' do
        value.low_stock_threshold = nil
        expect(value.formatted_treshold).to be_nil
      end
    end

    describe 'validations' do
      it 'rejects a negative threshold' do
        value.low_stock_threshold = -1
        expect(value).not_to be_valid
      end
    end

    describe '#data_different?' do
      it 'detects amount and unit changes' do
        expect(value.data_different?({ amount: value.amount.to_s })).to be false
        expect(value.data_different?({ amount: (value.amount + 1).to_s })).to be true
        expect(value.data_different?({ unit_item_id: -1 })).to be true
        expect(value.data_different?({})).to be false
      end
    end

    describe '#update_data!' do
      let!(:unit) { create :repository_stock_unit_item, repository_column: column, data: 'g' }

      it 'writes a ledger record with the delta and updates the value' do
        value.update!(amount: 10)
        expect do
          value.update_data!({ amount: '4', unit_item_id: unit.id, comment: 'used', low_stock_threshold: '2' },
                             acting_user)
        end.to change { value.repository_ledger_records.count }.by(1)
        value.reload
        expect(value.amount).to eq 4
        expect(value.low_stock_threshold).to eq 2
        expect(value.repository_stock_unit_item).to eq unit
        expect(value.last_modified_by).to eq acting_user
        record = value.repository_ledger_records.order(:id).last
        expect(record.amount).to eq(-6)
        expect(record.balance).to eq 4
        expect(record.comment).to eq 'used'
        expect(record.unit).to eq 'g'
      end

      it 'does not persist anything in preview mode' do
        original = value.amount
        expect do
          value.update_data!({ amount: '1', unit_item_id: unit.id }, acting_user, preview: true)
        end.not_to(change { value.repository_ledger_records.count })
        expect(value.reload.amount).to eq original
      end
    end

    describe 'low stock notification' do
      it 'is sent when saved with low status' do
        expect(LowStockNotification).to receive(:send_notifications)
          .with(hash_including(repository_row_id: cell.repository_row_id))
        value.update!(amount: 1, low_stock_threshold: 5)
      end

      it 'is not sent for normal status' do
        expect(LowStockNotification).not_to receive(:send_notifications)
        value.update!(amount: 100, low_stock_threshold: 5)
      end
    end

    describe 'unit change' do
      it 'propagates the unit to my module repository rows' do
        mm_row = create :mm_repository_row, repository_row: cell.repository_row, assigned_by: acting_user
        unit = create :repository_stock_unit_item, repository_column: column
        value.update!(repository_stock_unit_item: unit)
        expect(mm_row.reload.repository_stock_unit_item_id).to eq unit.id
      end
    end

    describe '.new_with_payload' do
      it 'builds a value with amount, threshold and unit' do
        unit = create :repository_stock_unit_item, repository_column: column
        attrs = { repository_cell: cell }
        built = described_class.new_with_payload({ amount: '7', low_stock_threshold: '2', 'unit_item_id' => unit.id },
                                                 attrs)
        expect(built.amount).to eq 7
        expect(built.low_stock_threshold).to eq 2
        expect(built.repository_stock_unit_item).to eq unit
      end

      it 'raises without an amount' do
        # bug: app/models/repository_stock_value.rb:173 raises RecordInvalid with a String, which
        # blows up with NoMethodError (`errors` on String) instead of a RecordInvalid
        expect { described_class.new_with_payload({}, {}) }.to raise_error(NoMethodError, /errors/)
      end
    end

    describe '.import_from_text' do
      let(:attrs) { { repository_cell_attributes: { repository_column: column } } }

      it 'returns nil for blank or non numeric text' do
        expect(described_class.import_from_text('', attrs)).to be_nil
        expect(described_class.import_from_text('abc', attrs)).to be_nil
      end

      it 'parses a bare number' do
        built = described_class.import_from_text('12.5', attrs)
        expect(built.amount).to eq BigDecimal('12.5')
        expect(built.repository_stock_unit_item).to be_nil
      end

      it 'reuses an existing unit' do
        unit = create :repository_stock_unit_item, repository_column: column, data: 'ml'
        column.reload
        built = described_class.import_from_text('3 ml', attrs)
        expect(built.repository_stock_unit_item).to eq unit
      end

      it 'creates a missing unit' do
        creator = create :user
        built = described_class.import_from_text('3 mol', attrs.merge(created_by: creator, last_modified_by: creator))
        expect(built.repository_stock_unit_item.data).to eq 'mol'
        expect(built.repository_stock_unit_item).to be_persisted
      end
    end

    describe '#snapshot!' do
      it 'copies the value onto the snapshot cell mapping the unit by name' do
        unit = create :repository_stock_unit_item, repository_column: column, data: 'ml'
        value.update!(repository_stock_unit_item: unit)
        snapshot_column = create :repository_column, :stock_type, repository: create(:repository)
        snapshot_unit = create :repository_stock_unit_item, repository_column: snapshot_column, data: 'ml'
        snapshot_column.reload
        snapshot_cell = build :repository_cell, repository_row: cell.repository_row,
                                                 repository_column: snapshot_column, value: nil
        snapshot_cell.value_type = 'RepositoryStockValue'
        snapshot_cell.save!(validate: false)
        expect { value.snapshot!(snapshot_cell) }.to change(described_class, :count).by(1)
        copy = described_class.order(:id).last
        expect(copy.repository_stock_unit_item).to eq snapshot_unit
        expect(copy.amount).to eq value.amount
      end
    end

    describe '.add_filter_condition' do
      let(:unit) { create :repository_stock_unit_item, repository_column: column, data: 'ml' }
      let(:rows) do
        RepositoryRow.joins('INNER JOIN repository_cells rc ON rc.repository_row_id = repository_rows.id ' \
                            'INNER JOIN repository_stock_values rsv ON rsv.id = rc.value_id')
      end

      before { value.update_columns(amount: 10, repository_stock_unit_item_id: unit.id) }

      def filter(operator, params)
        element = double(operator: operator, parameters: params.stringify_keys)
        described_class.add_filter_condition(rows, 'rsv', element)
      end

      {
        'equal_to' => [10, 11], 'unequal_to' => [11, 10], 'greater_than' => [9, 10],
        'greater_than_or_equal_to' => [10, 11], 'less_than' => [11, 10], 'less_than_or_equal_to' => [10, 9]
      }.each do |operator, (hit, miss)|
        it "supports #{operator}" do
          expect(filter(operator, value: hit.to_s, stock_unit: 'all').pluck(:id)).to eq [cell.repository_row_id]
          expect(filter(operator, value: miss.to_s, stock_unit: 'all')).to be_empty
        end
      end

      it 'supports between' do
        expect(filter('between', from: '5', to: '15', stock_unit: 'all').count).to eq 1
        expect(filter('between', from: '10', to: '15', stock_unit: 'all').count).to eq 0
      end

      it 'filters by unit selection' do
        expect(filter('equal_to', value: '10', stock_unit: 'none')).to be_empty
        expect(filter('equal_to', value: '10', stock_unit: unit.id.to_s).count).to eq 1
      end

      it 'returns the relation untouched for blank parameters' do
        expect(filter('equal_to', value: '', stock_unit: 'all')).to eq rows
        expect(filter('between', from: '', to: '3', stock_unit: 'all')).to eq rows
      end

      it 'raises for an unknown operator' do
        expect { filter('bogus', value: '1', stock_unit: 'all') }.to raise_error(ArgumentError)
      end
    end
  end
end
