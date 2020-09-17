# frozen_string_literal: true

require 'rails_helper'

describe MyModuleStatus, type: :model do
  let(:my_module_status) { build :my_module_status }

  it 'is valid' do
    expect(my_module_status).to be_valid
  end

  it 'should be of class MyModuleStatus' do
    expect(subject.class).to eq MyModuleStatus
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :color }
    it { should have_db_column :my_module_status_flow_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :previous_status_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :my_module_status_flow }
    it { should have_many(:my_modules).dependent(:nullify) }
    it { should have_many(:my_module_status_conditions).dependent(:destroy) }
    it { should have_many(:my_module_status_consequences).dependent(:destroy) }
    it { should have_many(:my_module_status_implications).dependent(:destroy) }
  end

  describe 'Validations' do
    describe '#name' do
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
    end

    describe '#description' do
      it { is_expected.to validate_length_of(:description).is_at_most(Constants::TEXT_MAX_LENGTH) }
    end
  end
end
