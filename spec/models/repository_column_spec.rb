# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumn, type: :model do
  let(:repository_column) { build :repository_column }

  it 'is valid' do
    expect(repository_column).to be_valid
  end

  it 'should be of class RepositoryColumn' do
    expect(subject.class).to eq RepositoryColumn
  end

  describe 'Database table' do
    it { should have_db_column :repository_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :name }
    it { should have_db_column :data_type }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :repository }
    it { should belong_to(:created_by).class_name('User') }
    it { should have_many :repository_cells }
    it { should have_many :repository_rows }
    it { should have_many :repository_list_items }
  end

  describe 'Validations' do
    describe '#name' do
      it { is_expected.to validate_presence_of :name }
      it { is_expected.to(validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)) }
      it { expect(repository_column).to validate_uniqueness_of(:name).scoped_to(:repository_id) }
    end

    describe '#created_by' do
      it { is_expected.to validate_presence_of :created_by }
    end

    describe '#repository' do
      it { is_expected.to validate_presence_of :repository }
    end

    describe '#data_type' do
      it { is_expected.to validate_presence_of :data_type }
    end
  end
end
