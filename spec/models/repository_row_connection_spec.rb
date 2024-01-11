require 'rails_helper'

RSpec.describe RepositoryRowConnection, type: :model do
  subject { create(:repository_row_connection) }

  it 'should be of class RepositoryRow' do
    expect(subject.class).to eq RepositoryRowConnection
  end

  describe 'Database table' do
    it { should have_db_column(:parent_id).of_type(:integer) }
    it { should have_db_column(:child_id).of_type(:integer) }
    it { should have_db_column(:created_by_id).of_type(:integer) }
    it { should have_db_column(:last_modified_by_id).of_type(:integer) }
    it { should have_db_index(:parent_id) }
    it { should have_db_index(:child_id) }
    it { should have_db_index(:created_by_id) }
    it { should have_db_index(:last_modified_by_id) }
  end

  describe 'Relations' do
    it { should belong_to(:parent).class_name('RepositoryRow').inverse_of(:child_connections).counter_cache(:child_connections_count) }
    it { should belong_to(:child).class_name('RepositoryRow').inverse_of(:parent_connections).counter_cache(:parent_connections_count) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid with a repository_row as both parent and child at the same time' do
      repository_row = create(:repository_row)
      connection = build(:repository_row_connection, parent: repository_row, child: repository_row)
      expect(connection).not_to be_valid
    end

    it 'is not valid with reciprocal parent and child' do
      parent_row = create(:repository_row)
      child_row = create(:repository_row)

      create(:repository_row_connection, parent: parent_row, child: child_row)
      reciprocal_connection = build(:repository_row_connection, parent: child_row, child: parent_row)

      expect(reciprocal_connection).not_to be_valid
    end

    it 'enforces uniqueness of parent-child pairs' do
      parent_row = create(:repository_row)
      child_row = create(:repository_row)

      create(:repository_row_connection, parent: parent_row, child: child_row)
      duplicate_connection = build(:repository_row_connection, parent: parent_row, child: child_row)

      expect(duplicate_connection).not_to be_valid
    end
  end
end
