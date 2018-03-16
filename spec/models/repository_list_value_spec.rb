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
    let!(:repository_column) { create :repository_column, name: 'My column' }
    let!(:repository_column) do
      create :repository_column, data_type: :RepositoryListValue
    end
    let!(:repository_row) { create :repository_row, name: 'My row' }
    let!(:repository_list_value) do
      create :repository_list_value, repository_cell_attributes: {
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
      repository_list_value.save
      expect(repository_list_value.reload.formatted).to eq 'my item'
    end

    it 'retuns only the the item related to the list' do
      repository_row_two = create :repository_row, name: 'New row'
      repository_list_value_two =
        create :repository_list_value, repository_cell_attributes: {
          repository_column: repository_column,
          repository_row: repository_row_two
        }
      list_item = create :repository_list_item,
                         data: 'new item',
                         repository: repository,
                         repository_column: repository_column
      repository_list_value.repository_list_item = list_item
      expect(repository_list_value.reload.formatted).to_not eq 'my item'
      expect(repository_list_value.formatted).to eq ''
    end

    it 'returns an empty string if no item selected' do
      list_item = create :repository_list_item,
                         data: 'my item',
                         repository: repository,
                         repository_column: repository_column
      expect(repository_list_value.reload.formatted).to eq ''
    end

    it 'returns an empty string if item does not exists' do
      repository_list_value.repository_list_item = nil
      expect(repository_list_value.reload.formatted).to eq ''
    end
  end

  describe '#data' do
    let!(:repository) { create :repository }
    let!(:repository_column) { create :repository_column, name: 'My column' }
    let!(:repository_column) do
      create :repository_column, data_type: :RepositoryListValue
    end
    let!(:repository_row) { create :repository_row, name: 'My row' }
    let!(:repository_list_value) do
      create :repository_list_value, repository_cell_attributes: {
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
      repository_list_value.save
      expect(repository_list_value.reload.data).to eq 'my item'
    end

    it 'retuns only the the item related to the list' do
      repository_row_two = create :repository_row, name: 'New row'
      repository_list_value_two =
        create :repository_list_value, repository_cell_attributes: {
          repository_column: repository_column,
          repository_row: repository_row_two
        }
      list_item = create :repository_list_item,
                         data: 'new item',
                         repository: repository,
                         repository_column: repository_column
      repository_list_value.repository_list_item = list_item
      expect(repository_list_value.reload.data).to_not eq 'my item'
      expect(repository_list_value.data).to be_nil
    end

    it 'returns an empty string if no item selected' do
      list_item = create :repository_list_item,
                         data: 'my item',
                         repository: repository,
                         repository_column: repository_column
      expect(repository_list_value.reload.data).to eq nil
    end

    it 'returns an empty string if item does not exists' do
      repository_list_value.repository_list_item = nil
      expect(repository_list_value.reload.data).to eq nil
    end
  end
end
