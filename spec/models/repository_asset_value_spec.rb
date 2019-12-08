# frozen_string_literal: true

require 'rails_helper'

describe RepositoryAssetValue, type: :model do
  let(:repository_asset_value) { build :repository_asset_value }

  it 'is valid' do
    expect(repository_asset_value).to be_valid
  end

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
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should belong_to(:asset).dependent(:destroy) }
    it { should have_one :repository_cell }
    it { should accept_nested_attributes_for(:repository_cell) }
  end

  describe 'Validations' do
    it { should validate_presence_of :repository_cell }
    it { should validate_presence_of :asset }
  end

  describe '#data' do
    it 'returns the asset' do
      asset = create :asset
      repository_asset_value = create :repository_asset_value, asset: asset

      expect(repository_asset_value.reload.formatted).to eq 'test.jpg'
    end
  end

  describe 'data_changed?' do
    it do
      expect(repository_asset_value.data_changed?(anything)).to be_truthy
    end
  end

  describe 'update_data!' do
    let(:user) { create :user }
    let(:new_file_base64) do
      {
        file_data: 'data:image/png;base64, someImageDataHere',
        filename: 'newFile.png'
      }
    end

    let(:new_file_with_signed_url) do
      {
        signed_url: 'someUrl'
      }
    end

    context 'when has signed_url' do
      it 'should change last_modified_by and data' do
        repository_asset_value.save

        expect { repository_asset_value.update_data!(new_file_with_signed_url, user) }
          .to(change { repository_asset_value.reload.last_modified_by.id }
                .and(change { repository_asset_value.reload.data }))
      end
    end

    context 'when has base464 file' do
      it 'should change last_modified_by and data' do
        repository_asset_value.save

        expect { repository_asset_value.update_data!(new_file_base64, user) }
          .to(change { repository_asset_value.reload.last_modified_by.id }
                .and(change { repository_asset_value.reload.data }))
      end
    end
  end
end
