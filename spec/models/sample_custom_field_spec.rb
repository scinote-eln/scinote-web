require 'rails_helper'

describe SampleCustomField, type: :model do
  it 'should be of class SampleCustomField' do
    expect(subject.class).to eq SampleCustomField
  end

  describe 'Database table' do
    it { should have_db_column :value }
    it { should have_db_column :custom_field_id }
    it { should have_db_column :sample_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :custom_field }
    it { should belong_to :sample }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :value }
    it { should validate_presence_of :custom_field }
    it { should validate_presence_of :sample }
    it do
      should validate_length_of(:value).is_at_most(Constants::NAME_MAX_LENGTH)
    end
  end
end
