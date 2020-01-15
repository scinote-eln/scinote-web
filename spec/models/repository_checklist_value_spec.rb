# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryChecklistValue, type: :model do
  let(:repository_checklist_item) { build :repository_checklist_item }
  let(:repository_checklist_value) { build :repository_checklist_value }

  it 'is valid' do
    repository_checklist_value.repository_checklist_items << repository_checklist_item
    expect(repository_checklist_value).to be_valid
  end

  it 'should be of class RepositoryChecklistValue' do
    expect(subject.class).to eq RepositoryChecklistValue
  end

  describe 'Database table' do
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should accept_nested_attributes_for(:repository_cell) }
  end
end
