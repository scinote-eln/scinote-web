# frozen_string_literal: true

require 'rails_helper'

describe Checklist, type: :model do
  let(:checklist) { build :checklist }

  it 'is valid' do
    expect(checklist).to be_valid
  end

  it 'should be of class Checklist' do
    expect(subject.class).to eq Checklist
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :step_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to(:step) }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should have_many :report_elements }
    it { should have_many :checklist_items }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :name }
    it { should validate_length_of(:name).is_at_most(Constants::TEXT_MAX_LENGTH) }
    it { should validate_presence_of :step }
  end
end
