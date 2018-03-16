require 'rails_helper'

describe RepositoryAssetValue, type: :model do
  it 'should be of class RepositoryAssetValue' do
    expect(subject.class).to eq RepositoryAssetValue
  end

  describe 'Database table' do
    it { should have_db_column :asset_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to(:asset).dependent(:destroy) }
    it { should have_one :repository_cell }
    it { should accept_nested_attributes_for(:repository_cell) }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :repository_cell }
    it { should validate_presence_of :asset }
  end

  describe '#data' do
    let!(:repository) { create :repository }
    let!(:repository_column) do
      create :repository_column,
             name: 'My column',
             data_type: :RepositoryAssetValue
    end
    let!(:repository_row) { create :repository_row, name: 'My row' }

    it 'returns the asset' do
      asset = create :asset, file_file_name: 'my file'
      repository_asset_value = create :repository_asset_value,
                                      asset: asset,
                                      repository_cell_attributes: {
                                        repository_column: repository_column,
                                        repository_row: repository_row
                                      }
      expect(repository_asset_value.reload.formatted).to eq 'my file'
    end
  end
end
