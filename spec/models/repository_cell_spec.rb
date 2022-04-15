# frozen_string_literal: true

require 'rails_helper'

describe RepositoryCell, type: :model do
  let(:repository_cell) { build :repository_cell }
  let(:repository_cell_t) { build :repository_cell, :text_value }
  let(:repository_cell_d) { build :repository_cell, :date_time_value }
  let(:repository_cell_l) { build :repository_cell, :list_value }
  let(:repository_cell_a) { build :repository_cell, :asset_value }
  let(:repository_cell_s) { build :repository_cell, :status_value }
  let(:repository_cell_d_r) { build :repository_cell, :date_time_range_value }
  let(:repository_cell_s_v) { build :repository_cell, :stock_value }

  context 'when do not have value' do
    it 'is not valid' do
      expect(repository_cell).not_to be_valid
    end
  end

  context 'when have value' do
    it 'is valid for text value' do
      expect(repository_cell_t).to be_valid
    end

    it 'is valid for data time value' do
      expect(repository_cell_d).to be_valid
    end

    it 'is valid for list value' do
      expect(repository_cell_l).to be_valid
    end

    it 'is valid for asset value' do
      expect(repository_cell_a).to be_valid
    end

    it 'is valid for status value' do
      expect(repository_cell_s).to be_valid
    end

    it 'is valid for date time range value' do
      expect(repository_cell_d_r).to be_valid
    end

    it 'is valid for stock value' do
      expect(repository_cell_s_v).to be_valid
    end
  end

  it 'should be of class RepositoryCell' do
    expect(subject.class).to eq RepositoryCell
  end

  describe 'Database table' do
    it { should have_db_column :repository_row_id }
    it { should have_db_column :repository_column_id }
    it { should have_db_column :value_id }
    it { should have_db_column :value_type }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :repository_row }
    it { should belong_to :repository_column }
  end
end
