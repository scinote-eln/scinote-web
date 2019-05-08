# frozen_string_literal: true

require 'rails_helper'

describe SampleMyModule, type: :model do
  let(:sample_my_module) { build :sample_my_module }

  it 'is valid' do
    expect(sample_my_module).to be_valid
  end

  it 'should be of class SampleMyModule' do
    expect(subject.class).to eq SampleMyModule
  end

  describe 'Database table' do
    it { should have_db_column :sample_id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :assigned_by_id }
    it { should have_db_column :assigned_on }
  end

  describe 'Relations' do
    it { should belong_to(:assigned_by).class_name('User') }
    it { should belong_to :sample }
    it { should belong_to :my_module }
  end

  describe 'Validations' do
    describe '#sample' do
      it { should validate_presence_of :sample }
      it { expect(sample_my_module).to validate_uniqueness_of(:sample_id).scoped_to(:my_module_id) }
    end

    describe '#my_module' do
      it { should validate_presence_of :my_module }
    end
  end
end
