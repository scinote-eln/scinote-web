# frozen_string_literal: true

require 'rails_helper'

describe CustomField, type: :model do
  let(:custom_field) { build :custom_field }

  it 'is valid' do
    expect(custom_field).to be_valid
  end
  it 'should be of class CustomField' do
    expect(subject.class).to eq CustomField
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :user_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :team }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should have_many :sample_custom_fields }
  end

  describe 'Validations' do
    describe '#name' do
      it { is_expected.to validate_presence_of :name }
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
      it do
        is_expected.to validate_exclusion_of(:name).in_array(
          ['Assigned', 'Sample name', 'Sample type', 'Sample group', 'Added on', 'Added by']
        )
      end
      it do
        allow_any_instance_of(CustomField).to receive(:update_samples_table_state)

        expect(custom_field).to validate_uniqueness_of(:name).scoped_to(:team_id)
      end
    end

    describe '#user' do
      it { is_expected.to validate_presence_of :user }
    end
  end
end
