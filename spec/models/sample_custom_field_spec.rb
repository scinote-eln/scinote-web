# frozen_string_literal: true

require 'rails_helper'

describe SampleCustomField, type: :model do
  it 'is valid' do
    # Need this records because of after_create callback
    sample = create :sample
    create :samples_table, user: sample.user, team: sample.team
    custom_field = create :custom_field, user: sample.user, team: sample.team
    sample_custom_filed = create :sample_custom_field, sample: sample, custom_field: custom_field

    expect(sample_custom_filed).to be_valid
  end

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

  describe 'Validations' do
    describe '#value' do
      it { is_expected.to validate_presence_of :value }
      it { is_expected.to validate_length_of(:value).is_at_most(Constants::NAME_MAX_LENGTH) }
    end

    describe '#custom_field' do
      it { is_expected.to validate_presence_of :custom_field }
    end

    describe '#sample' do
      it { is_expected.to validate_presence_of :sample }
    end
  end
end
