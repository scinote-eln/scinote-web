# frozen_string_literal: true

require 'rails_helper'

describe Sample, type: :model do
  let(:sample) { build :sample }

  it 'is valid' do
    expect(sample).to be_valid
  end

  it 'should be of class Sample' do
    expect(subject.class).to eq Sample
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :user_id }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :sample_group_id }
    it { should have_db_column :sample_type_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :nr_of_modules_assigned_to }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :team }
    it { should belong_to :sample_group }
    it { should belong_to :sample_type }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_many :sample_my_modules }
    it { should have_many :my_modules }
    it { should have_many :sample_custom_fields }
    it { should have_many :custom_fields }
  end

  describe 'Validations' do
    describe '#name' do
      it { is_expected.to validate_presence_of :name }
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
    end

    describe '#user' do
      it { is_expected.to validate_presence_of :user }
    end

    describe '#team' do
      it { is_expected.to validate_presence_of :team }
    end
  end
end
