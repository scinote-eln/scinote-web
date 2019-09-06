# frozen_string_literal: true

require 'rails_helper'

describe StepAsset, type: :model do
  let(:step_asset) { build :step_asset }

  it 'is valid' do
    expect(step_asset).to be_valid
  end

  it 'should be of class StepAsset' do
    expect(subject.class).to eq StepAsset
  end

  describe 'Database table' do
    it { should have_db_column :step_id }
    it { should have_db_column :asset_id }
  end

  describe 'Relations' do
    it { should belong_to :step }
    it { should belong_to :asset }
  end

  describe 'Validations' do
    it { should validate_presence_of :step }
    it { should validate_presence_of :asset }
  end
end
