require 'rails_helper'

describe Repository, type: :model do
  it 'should be of class Repository' do
    expect(subject.class).to eq Repository
  end

  describe 'Database table' do
    it { should have_db_column :team_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to(:created_by).class_name('User') }
    it { should have_many :repository_rows }
    it { should have_many :repository_table_states }
    it { should have_many :report_elements }
    it { should have_many(:repository_list_items).dependent(:destroy) }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :team }
    it { should validate_presence_of :created_by }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end

    it 'should have uniq name scoped to team' do
      create :repository, name: 'Repository One'
      repo = build :repository, name: 'Repository One'
      expect(repo).to_not be_valid
    end

    it 'should have uniq name scoped to team calse insensitive' do
      create :repository, name: 'Repository One'
      repo = build :repository, name: 'REPOSITORY ONE'
      expect(repo).to_not be_valid
    end
  end
end
