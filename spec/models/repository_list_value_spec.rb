require 'rails_helper'

RSpec.describe RepositoryListValue, type: :model do
  it 'should be of class RepositoryListValue' do
    expect(subject.class).to eq RepositoryListValue
  end

  describe 'Database table' do
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :repository_list_item_id }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to(:repository_list_item) }
    it { should accept_nested_attributes_for(:repository_cell) }
  end

  describe '#formatted' do
    let!(:repository) { create :repository }
    let!(:repository_column) do
      create :repository_column, name: 'My column',
                                 data_type: :RepositoryListValue
    end
    let!(:repository_row) { create :repository_row, name: 'My row' }
    let!(:repository_list_value) do
      build :repository_list_value, repository_cell_attributes: {
        repository_column: repository_column,
        repository_row: repository_row
      }
    end

    it 'returns the formatted data of a selected item' do
      list_item = create :repository_list_item,
                         data: 'my item',
                         repository: repository,
                         repository_column: repository_column
      repository_list_value.repository_list_item = list_item
      repository_list_value.save!
      expect(repository_list_value.reload.formatted).to eq 'my item'
    end
  end

  describe '#data' do
    let!(:repository) { create :repository }
    let!(:repository_column) do
      create :repository_column, name: 'My column',
                                 data_type: :RepositoryListValue
    end
    let!(:repository_row) { create :repository_row, name: 'My row' }
    let!(:repository_list_value) do
      build :repository_list_value, repository_cell_attributes: {
        repository_column: repository_column,
        repository_row: repository_row
      }
    end

    it 'returns the data of a selected item' do
      list_item = create :repository_list_item,
                         data: 'my item',
                         repository: repository,
                         repository_column: repository_column
      repository_list_value.repository_list_item = list_item
      repository_list_value.save!
      expect(repository_list_value.reload.data).to eq 'my item'
    end

    it 'retuns only the the item related to the list' do
      repository_column_two = create :repository_column, name: 'New column'
      list_item = create :repository_list_item,
                         data: 'new item',
                         repository: repository,
                         repository_column: repository_column_two
      repository_list_value_two = build :repository_list_value,
                                        repository_cell_attributes: {
                                          repository_column: repository_column,
                                          repository_row: repository_row
                                        }
      repository_list_value_two.repository_list_item = list_item
      saved = repository_list_value_two.save
      expect(saved).to eq false
    end
  end
end
