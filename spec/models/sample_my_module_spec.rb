require 'rails_helper'

describe SampleMyModule, type: :model do
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

  describe 'Should be a valid object' do
    it { should validate_presence_of :sample }
    it { should validate_presence_of :my_module }

    it 'should have one sample assigned per model' do
      sample = create :sample
      my_module = create :my_module, name: 'Module one'
      create :sample_my_module, sample: sample, my_module: my_module
      new_smm = build :sample_my_module, sample: sample, my_module: my_module
      expect(new_smm).to_not be_valid
    end
  end
end
