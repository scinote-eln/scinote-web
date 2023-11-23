# frozen_string_literal: true

require 'rails_helper'

describe RepositoryLedgerRecord, type: :model do
  let(:repository_ledger_record) { build :repository_ledger_record }
  let(:repository_stock_value_new) { build :repository_stock_value }

  it 'is valid' do
    expect(repository_ledger_record).to be_valid
  end

  it 'should be of class RepositoryLedgerRecord' do
    expect(subject.class).to eq RepositoryLedgerRecord
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :repository_stock_value_id }
    it { should have_db_column :reference_id }
    it { should have_db_column :reference_type }
    it { should have_db_column :amount }
    it { should have_db_column :balance }
    it { should have_db_column :user_id }
    it { should have_db_column :comment }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Associations' do
    it { should belong_to(:repository_stock_value) }
    it { should belong_to(:reference) }
    it { should belong_to(:user) }
  end
end
