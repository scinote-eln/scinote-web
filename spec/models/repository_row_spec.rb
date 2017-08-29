require 'rails_helper'

describe RepositoryRow, type: :model do
  it 'should be of class RepositoryRow' do
    expect(subject.class).to eq RepositoryRow
  end

  describe 'Database table' do
    it { should have_db_column :repository_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :repository }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :repository_cells }
    it { should have_many :repository_columns }
    it { should have_many :my_module_repository_rows }
    it { should have_many :my_modules }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :created_by }
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
  end
end
