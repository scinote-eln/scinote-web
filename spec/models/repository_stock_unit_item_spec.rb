# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStockUnitItem, type: :model do
  let(:repository_stock_unit_item) { build :repository_stock_unit_item }

  it 'is valid' do
    expect(repository_stock_unit_item).to be_valid
  end

  it 'should be of class RepositoryStockUnitItem' do
    expect(subject.class).to eq RepositoryStockUnitItem
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :data }
    it { should have_db_column :repository_column_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Associations' do
    it { should belong_to(:repository_column) }
    it { should belong_to(:created_by) }
    it { should belong_to(:last_modified_by) }
  end

end
