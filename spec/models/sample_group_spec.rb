# frozen_string_literal: true

require 'rails_helper'

describe SampleGroup, type: :model do
  let(:sample_group) { build :sample_group }

  it 'is valid' do
    expect(sample_group).to be_valid
  end

  it 'should be of class SampleGroup' do
    expect(subject.class).to eq SampleGroup
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :color }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }

    it 'have many samples' do
      table = SampleGroup.reflect_on_association(:samples)
      expect(table.macro).to eq(:has_many)
    end
  end

  describe 'Validations' do
    describe '#name' do
      it { is_expected.to validate_presence_of :name }
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
      it { expect(sample_group).to validate_uniqueness_of(:name).scoped_to(:team_id).case_insensitive }
    end

    describe '#color' do
      it { is_expected.to validate_presence_of :color }
      it { is_expected.to validate_length_of(:color).is_at_most(Constants::COLOR_MAX_LENGTH) }
    end

    describe '#team' do
      it { is_expected.to validate_presence_of :team }
    end
  end
end
