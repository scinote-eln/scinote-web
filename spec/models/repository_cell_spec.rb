require 'rails_helper'

describe RepositoryCell, type: :model do
  it 'should be of class RepositoryCell' do
    expect(subject.class).to eq RepositoryCell
  end

  describe 'Database table' do
    it { should have_db_column :repository_row_id }
    it { should have_db_column :repository_column_id }
    it { should have_db_column :value_id }
    it { should have_db_column :value_type }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :repository_row }
    it { should belong_to :repository_column }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :repository_column }
    it do
      should validate_uniqueness_of(:repository_row)
              .scoped_to(:repository_column)
    end
  end
end
