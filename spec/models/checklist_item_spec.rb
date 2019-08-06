# frozen_string_literal: true

require 'rails_helper'

describe ChecklistItem, type: :model do
  let(:checklist_item) { build :checklist_item }

  it 'is valid' do
    expect(checklist_item).to be_valid
  end

  it 'should be of class ChecklistItem' do
    expect(subject.class).to eq ChecklistItem
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :text }
    it { should have_db_column :checked }
    it { should have_db_column :checklist_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :position }
  end

  describe 'Relations' do
    it { should belong_to(:checklist) }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
  end

  describe 'Validations' do
    it { should validate_presence_of :text }
    it { should validate_length_of(:text).is_at_most(Constants::TEXT_MAX_LENGTH) }
    it { should validate_presence_of :checklist }
    it { should validate_inclusion_of(:checked).in_array([true, false]) }
  end
end
