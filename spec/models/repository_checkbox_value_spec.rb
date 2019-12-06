# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryCheckboxValue, type: :model do
  let(:repository_checkbox_value) { build :repository_checkbox_value }

  it 'is valid' do
    expect(repository_checkbox_value).to be_valid
  end

  it 'should be of class RepositoryCheckboxValue' do
    expect(subject.class).to eq RepositoryCheckboxValue
  end

  describe 'Database table' do
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :repository_checkboxes_items }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should accept_nested_attributes_for(:repository_cell) }
  end
end
