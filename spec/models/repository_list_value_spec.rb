require 'rails_helper'

RSpec.describe RepositoryListValue, type: :model do
  it 'should be of class RepositoryListValue' do
    expect(subject.class).to eq RepositoryListValue
  end

  describe 'Database table' do
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :selected_item }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :repository_list_items }
    it { should accept_nested_attributes_for(:repository_cell) }
  end

  describe '#data' do
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

    it 'returns the name of a selected item' do
      list_item = create :repository_list_item,
                         repository_list_value: repository_list_value,
                         name: 'my item'
      repository_list_value.update_attribute(:selected_item, list_item.id)
      expect(repository_list_value.reload.formated).to eq 'my item'
    end

    it 'retuns only the the item related to the list' do
      repository_row_two = create :repository_row, name: 'New row'
      repository_list_value_two =
        create :repository_list_value, repository_cell_attributes: {
          repository_column: repository_column,
          repository_row: repository_row_two
        }
      list_item = create :repository_list_item,
                         repository_list_value: repository_list_value_two,
                         name: 'new item'
      repository_list_value.update_attribute(:selected_item, list_item.id)
      expect(repository_list_value.reload.formated).to_not eq 'my item'
      expect(repository_list_value.formated).to eq ''
    end

    it 'returns an empty string if no item selected' do
      list_item = create :repository_list_item,
                         repository_list_value: repository_list_value,
                         name: 'my item'
      expect(repository_list_value.reload.formated).to eq ''
    end

    it 'returns an empty string if item does not exists' do
      repository_list_value.update_attribute(:selected_item, 9999999999)
      expect(repository_list_value.reload.formated).to eq ''
    end
  end
end
