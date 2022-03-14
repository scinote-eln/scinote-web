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

  describe 'data_different?' do
    it do
      expect(repository_asset_value.data_different?(anything)).to be_truthy
    end
  end

  describe 'update_data!' do
    let(:user) { create :user }
    let(:new_file_base64) do
      {
        file_data: 'data:image/png;base64, someImageDataHere',
        file_name: 'newFile.png'
      }
    end

    let(:new_file_with_direct_upload_token) { 'Token' }

    context 'when update data' do
      # context 'when has direct_upload_token' do
      #   it 'should change last_modified_by and data' do
      #     repository_asset_value.save
      #
      #     expect { repository_asset_value.update_data!(new_file_with_direct_upload_token, user) }
      #       .to(change { repository_asset_value.reload.last_modified_by.id }
      #             .and(change { repository_asset_value.reload.data }))
      #   end
      # end

      context 'when has base64 file' do
        it 'should change last_modified_by and data' do
          repository_asset_value.save

          expect { repository_asset_value.update_data!(new_file_base64, user) }
            .to(change { repository_asset_value.reload.last_modified_by.id }
                  .and(change { repository_asset_value.reload.data }))
        end
      end
    end
  end

  describe 'self.new_with_payload' do
    let(:user) { create :user }
    let(:column) { create :repository_column }
    let(:cell) { build :repository_cell, repository_column: column }
    let(:attributes) do
      {
        repository_cell: cell,
        created_by: user,
        last_modified_by: user
      }
    end

    # context 'when has direct_upload_token' do
    #   let(:payload) { {direct_upload_token: 'Token'} }
    #
    #   it do
    #     expect(RepositoryAssetValue.new_with_payload(payload, attributes))
    #       .to be_an_instance_of RepositoryAssetValue
    #   end
    #
    #   it do
    #     expect { RepositoryAssetValue.new_with_payload(payload, attributes) }.to change(Asset, :count).by(1)
    #   end
    # end

    context 'when has base64 file' do
      let(:payload) do
        {
          file_data: 'data:image/png;base64, someImageDataHere',
          file_name: 'newFile.png'
        }
      end
      it do
        expect(RepositoryAssetValue.new_with_payload(payload, attributes))
          .to be_an_instance_of RepositoryAssetValue
      end

      it do
        expect { RepositoryAssetValue.new_with_payload(payload, attributes) }.to change(Asset, :count).by(1)
      end
    end
  end
end
