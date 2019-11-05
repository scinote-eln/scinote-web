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
  end
end
