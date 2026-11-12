# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDatatableHelper, type: :helper do
  let(:user) { create(:user) }
  let(:team) { create(:team) }
  let(:repository) { create(:repository, team: team, created_by: user) }
  let(:my_module) { create(:my_module) }

  before do
    without_partial_double_verification { allow(helper).to receive(:current_user).and_return(user) }
  end

  describe '#serialize_repository_cell_value' do
    it 'uses the serializer for the column data type and passes the scope' do
      cell = double('cell', value: 'value', repository_column: double('column', data_type: 'RepositoryTextValue'))
      serializer = double('serializer', serializable_hash: { value: 'x' })
      expect(RepositoryDatatable::RepositoryTextValueSerializer).to receive(:new).with(
        'value',
        scope: hash_including(team: team, user: user, repository: repository, options: { reminders_enabled: true })
      ).and_return(serializer)

      expect(helper.serialize_repository_cell_value(cell, team, repository, reminders_enabled: true))
        .to eq(value: 'x')
    end

    it 'selects the serializer matching each core repository value type' do
      {
        'RepositoryTextValue' => 'RepositoryTextValueSerializer',
        'RepositoryNumberValue' => 'RepositoryNumberValueSerializer',
        'RepositoryListValue' => 'RepositoryListValueSerializer',
        'RepositoryChecklistValue' => 'RepositoryChecklistValueSerializer',
        'RepositoryStatusValue' => 'RepositoryStatusValueSerializer',
        'RepositoryTimeValue' => 'RepositoryTimeValueSerializer',
        'RepositoryDateValue' => 'RepositoryDateValueSerializer',
        'RepositoryDateTimeValue' => 'RepositoryDateTimeValueSerializer',
        'RepositoryDateRangeValue' => 'RepositoryDateRangeValueSerializer',
        'RepositoryTimeRangeValue' => 'RepositoryTimeRangeValueSerializer',
        'RepositoryDateTimeRangeValue' => 'RepositoryDateTimeRangeValueSerializer',
        'RepositoryAssetValue' => 'RepositoryAssetValueSerializer',
        'RepositoryStockValue' => 'RepositoryStockValueSerializer',
        'RepositoryStockConsumptionValue' => 'RepositoryStockConsumptionValueSerializer'
      }.each do |data_type, serializer_name|
        serializer_class = "RepositoryDatatable::#{serializer_name}".constantize
        cell = double('cell', value: 'v', repository_column: double('column', data_type: data_type))
        expect(serializer_class).to receive(:new).and_return(double('serializer', serializable_hash: { type: data_type }))

        expect(helper.serialize_repository_cell_value(cell, team, repository)).to eq(type: data_type)
      end
    end

    it 'uses the serializer registered by extensions for unknown value types' do
      cell = double('cell', value: 'v', value_type: 'RepositoryFancyValue',
                            repository_column: double('column', data_type: 'RepositoryFancyValue'))
      serializer_class = double('extra_serializer')
      serializer = double('serializer', serializable_hash: { extra: true })
      stub_const('Extends::REPOSITORY_EXTRA_VALUE_SERIALIZERS', { 'RepositoryFancyValue' => serializer_class })
      expect(serializer_class).to receive(:new).and_return(serializer)

      expect(helper.serialize_repository_cell_value(cell, team, repository)).to eq(extra: true)
    end
  end

  describe '#display_stock_warnings?' do
    it 'shows warnings for live repositories but not for snapshots' do
      expect(helper.display_stock_warnings?(repository)).to be true
      snapshot = create(:repository_snapshot, original_repository: repository, my_module: my_module)
      expect(helper.display_stock_warnings?(snapshot)).to be false
    end
  end
end
