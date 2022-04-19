# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStockValue, type: :model do
  let(:repository_stock_value) { build :repository_stock_value }
  let(:repository) { build :repository }
  let(:user) { build :user }


  it 'is valid' do
    expect(repository_stock_value).to be_valid
  end

  it 'should be of class RepositoryStockValue' do
    expect(subject.class).to eq RepositoryStockValue
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :amount }
    it { should have_db_column :repository_stock_unit_item_id }
    it { should have_db_column :type }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :low_stock_threshold }
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:repository_stock_unit_item).optional }
    it { is_expected.to belong_to(:created_by).optional }
    it { is_expected.to belong_to(:last_modified_by).optional }
  end


  describe 'Saving stock value' do
    let(:repository_stock_value1) { build :repository_stock_value }
    it 'Save stock value' do
      expect { repository_stock_value.save }.to change(RepositoryStockValue, :count).by(1)
    end

    it 'Updating stock value' do
      repository_stock_value.save
      expect { repository_stock_value.update_data!({amount: 10, low_stock_threshold:''}, user) }
        .to change(RepositoryStockValue, :count).by(0)
    end

    it 'Updating stock value with ledger' do
      repository_stock_value.save
      expect { repository_stock_value.update_stock_with_ledger!(10, repository, "") }
        .to (change(RepositoryLedgerRecord, :count).by(1))
    end
  end
end
