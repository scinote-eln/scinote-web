require 'rails_helper'

describe RepositoryColumn, type: :model do
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

  describe 'Should be a valid object' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :created_by }
    it { should validate_presence_of :repository }
    it { should validate_presence_of :data_type }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
    it 'have uniq name scoped to repository' do
      create :repository_column, name: 'Repo One'
      column_two = build :repository_column, name: 'Repo One'

      expect(column_two).to_not be_valid
    end
  end
end
