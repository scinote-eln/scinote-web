# frozen_string_literal: true

require 'rails_helper'

describe MyModuleGroup, type: :model do
  let(:my_module_group) { build :my_module_group }

  it 'is valid' do
    expect(my_module_group).to be_valid
  end

  it 'should be of class MyModuleGroup' do
    expect(subject.class).to eq MyModuleGroup
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :experiment_id }
  end

  describe 'Relations' do
    it { should belong_to(:experiment) }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should have_many(:my_modules) }
  end

  describe 'Validations' do
    it { should validate_presence_of :experiment }
  end
end
