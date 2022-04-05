# frozen_string_literal: true

require 'rails_helper'

describe MyModuleRepositoryRow, type: :model do
  let(:my_module_repository_row) { build :mm_repository_row }

  let(:user) { create :user }
  let(:repository_stock_value) { create :repository_stock_value }

  let(:repository_row) { create :repository_row, repository_stock_value: repository_stock_value }
  let(:my_module_repository_row_stock) { create :mm_repository_row,
                                                 repository_row: repository_row,
                                                 assigned_by: user,
                                                 last_modified_by: user
                                        }

  it 'is valid' do
    expect(my_module_repository_row).to be_valid
  end

  it 'should be of class MyModuleRepositoryRow' do
    expect(subject.class).to eq MyModuleRepositoryRow
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :repository_row_id }
    it { should have_db_column :repository_stock_unit_item_id }
    it { should have_db_column :stock_consumption }
    it { should have_db_column :my_module_id }
    it { should have_db_column :assigned_by_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:my_module) }
    it { should belong_to(:repository_stock_unit_item).optional }
    it { should belong_to(:assigned_by).class_name('User').optional }
    it { should belong_to(:repository_row) }
  end

  describe 'Repository ledger record' do
    it 'Ledger creation on changed consumption' do
      my_module_repository_row_stock.stock_consumption = 10.0
      expect { my_module_repository_row_stock.save! }
        .to change(RepositoryLedgerRecord, :count).by(1)
    end
  end
end
