# frozen_string_literal: true

require 'rails_helper'

describe Table, type: :model do
  let(:table) { build :table }

  it 'is valid' do
    expect(table).to be_valid
  end

  it 'should be of class Table' do
    expect(subject.class).to eq Table
  end

  describe 'Database table' do
    it { should have_db_column :contents }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :data_vector }
    it { should have_db_column :name }
    it { should have_db_column :team_id }
  end

  describe 'Relations' do
    it { should belong_to(:team).optional }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should have_one :step_table }
    it { should have_one :step }
    it { should have_one :result_table }
    it { should have_one :result }
    it { should have_many :report_elements }
  end

  describe 'Validations' do
    describe '#contents' do
      it { is_expected.to validate_presence_of :contents }
      it { is_expected.to validate_length_of(:contents).is_at_most(Constants::TABLE_JSON_MAX_SIZE_MB.megabytes) }
    end

    describe '#name' do
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
    end

    describe '#sheet_name' do
      def table_attrs(sheet_name = nil)
        { name: Faker::Name.unique.name,
          contents: { data: [%w(A B C)] }.to_json,
          metadata: (sheet_name ? { sheet_name: sheet_name } : {}) }
      end

      context 'when table belongs to a step' do
        let(:protocol) { create :protocol }
        let(:step) { create :step, protocol: protocol }

        it 'is invalid when sheet_name is not unique within the protocol' do
          step.tables.create!(table_attrs('Sheet1'))
          table = create(:step, protocol: protocol).tables.create!(table_attrs('Sheet2'))

          table.metadata = { sheet_name: 'Sheet1' }

          expect(table).not_to be_valid
          expect(table.errors[:sheet_name]).to include(
            I18n.t('activerecord.errors.models.table.attributes.sheet_name.not_unique_in_context',
                   parent_class: Protocol, parent_id: protocol.id)
          )
        end

        it 'is valid when sheet_name is unique within the protocol' do
          step.tables.create!(table_attrs('Sheet1'))
          table = step.tables.create!(table_attrs('Sheet2'))

          expect(table).to be_valid
        end

        it 'is valid when sheet_name duplicates a table belonging to a different protocol' do
          step.tables.create!(table_attrs('Sheet1'))
          table = create(:step).tables.create!(table_attrs('Sheet2'))

          table.metadata = { sheet_name: 'Sheet1' }

          expect(table).to be_valid
        end
      end

      context 'when table belongs to a result' do
        let(:my_module) { create :my_module }

        it 'is invalid when sheet_name is not unique within the my_module' do
          create(:result, my_module: my_module).tables.create!(table_attrs('Sheet1'))
          table = create(:result, my_module: my_module).tables.create!(table_attrs('Sheet2'))

          table.metadata = { sheet_name: 'Sheet1' }

          expect(table).not_to be_valid
          expect(table.errors[:sheet_name]).to include(
            I18n.t('activerecord.errors.models.table.attributes.sheet_name.not_unique_in_context',
                   parent_class: MyModule, parent_id: my_module.id)
          )
        end

        it 'is valid when sheet_name duplicates a table belonging to a different my_module' do
          create(:result, my_module: my_module).tables.create!(table_attrs('Sheet1'))
          table = create(:result).tables.create!(table_attrs('Sheet2'))

          table.metadata = { sheet_name: 'Sheet1' }

          expect(table).to be_valid
        end
      end

      context 'when table belongs to a result template' do
        let(:protocol) { create :protocol }

        it 'is invalid when sheet_name is not unique within the protocol' do
          create(:result_template, protocol: protocol).tables.create!(table_attrs('Sheet1'))
          table = create(:result_template, protocol: protocol).tables.create!(table_attrs('Sheet2'))

          table.metadata = { sheet_name: 'Sheet1' }

          expect(table).not_to be_valid
          expect(table.errors[:sheet_name]).to include(
            I18n.t('activerecord.errors.models.table.attributes.sheet_name.not_unique_in_context',
                   parent_class: Protocol, parent_id: protocol.id)
          )
        end
      end

      it 'is valid without a sheet_name even if a duplicate exists in the same context' do
        step = create :step
        step.tables.create!(table_attrs('Sheet1'))
        table = step.tables.create!(table_attrs)

        expect(table).to be_valid
      end
    end
  end
end
