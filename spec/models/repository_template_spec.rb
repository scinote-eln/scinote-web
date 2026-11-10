# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTemplate, type: :model do
  let(:repository_template) { build :repository_template }

  it 'is valid' do
    expect(repository_template).to be_valid
  end

  it 'should be of class Repository Template' do
    expect(subject.class).to eq RepositoryTemplate
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :team_id }
    it { should have_db_column :column_definitions }
    it { should have_db_column :predefined }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should have_many(:repositories).dependent(:nullify) }
  end

  describe 'predefined templates' do
    {
      default: [],
      cell_lines: %w(RepositoryTextValue RepositoryListValue RepositoryStockValue RepositoryNumberValue
                     RepositoryDateValue RepositoryStatusValue RepositoryAssetValue),
      equipment: %w(RepositoryDateValue RepositoryStatusValue RepositoryAssetValue RepositoryTextValue),
      chemicals_and_reagents: %w(RepositoryTextValue RepositoryStockValue RepositoryDateValue RepositoryListValue
                                 RepositoryAssetValue)
    }.each do |factory_method, expected_types|
      describe ".#{factory_method}" do
        subject(:template) { described_class.public_send(factory_method) }

        it 'builds an unsaved predefined template with a name' do
          expect(template).to be_new_record
          expect(template.predefined).to be true
          expect(template.name).to be_present
        end

        it 'only uses known column types and named columns' do
          types = template.column_definitions.map { |d| d['column_type'] }.uniq
          expect(types).to match_array(expected_types.map { |t| Extends::REPOSITORY_DATA_TYPES[t.to_sym] }) if expected_types.any?
          expect(types - Extends::REPOSITORY_DATA_TYPES.values).to be_empty
          expect(template.column_definitions.map { |d| d['params']['name'] }).to all(be_present)
        end
      end
    end

    it 'default has no column definitions' do
      expect(described_class.default.column_definitions).to eq []
    end

    it 'equipment defines reminders on the calibration date column' do
      calibration = described_class.equipment.column_definitions.first
      expect(calibration['params']).to include('reminder_value' => '1', 'reminder_unit' => '2419200')
    end

    it 'cell_lines stock column uses default units plus vials' do
      stock = described_class.cell_lines.column_definitions.find do |d|
        d['column_type'] == Extends::REPOSITORY_DATA_TYPES[:RepositoryStockValue]
      end
      units = stock['params']['repository_stock_unit_items_attributes'].map { |u| u['data'] }
      expect(units).to include(*RepositoryStockUnitItem::DEFAULT_UNITS.map(&:to_s))
      expect(units.size).to eq RepositoryStockUnitItem::DEFAULT_UNITS.size + 1
    end
  end
end
