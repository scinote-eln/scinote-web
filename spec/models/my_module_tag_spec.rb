require 'rails_helper'

describe MyModuleTag, type: :model do
  it 'should be of class MyModuleTag' do
    expect(subject.class).to eq MyModuleTag
  end

  describe 'Database table' do
    it { should have_db_column :my_module_id }
    it { should have_db_column :tag_id }
    it { should have_db_column :created_by_id }
  end

  describe 'Relations' do
    it { should belong_to :my_module }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to :tag }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :my_module }
    it { should validate_presence_of :tag }
  end
end
