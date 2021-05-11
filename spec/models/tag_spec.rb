# frozen_string_literal: true

require 'rails_helper'

describe Tag, type: :model do
  let(:tag) { build :tag }

  it 'is valid' do
    expect(tag).to be_valid
  end

  it 'should be of class Tag' do
    expect(subject.class).to eq Tag
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :color }
    it { should have_db_column :project_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to :project }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should have_many :my_module_tags }
    it { should have_many :my_modules }
  end

  describe 'Validations' do
    describe '#name' do
      it { is_expected.to validate_presence_of :name }
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
    end

    describe '#color' do
      it { is_expected.to validate_presence_of :color }
      it { is_expected.to validate_length_of(:color).is_at_most(Constants::COLOR_MAX_LENGTH) }
    end

    describe '#projects' do
      it { is_expected.to validate_presence_of :project }
    end
  end
end
