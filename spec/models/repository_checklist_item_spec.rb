# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RepositoryChecklistItem, type: :model do
  let(:repository_checklist_item) { build :repository_checklist_item }

  it 'is valid' do
    expect(repository_checklist_item).to be_valid
  end

  it 'should be of class RepositoryChecklistItem' do
    expect(subject.class).to eq RepositoryChecklistItem
  end

  describe 'Database table' do
    it { should have_db_column :data }
    it { should have_db_column :repository_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :repository_column_id }
  end

  describe 'Relations' do
    it { should belong_to :repository }
    it { should belong_to :repository_column }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
  end

  describe 'Validations' do
    describe '#data' do
      it { is_expected.to validate_presence_of(:data) }
      it { is_expected.to validate_length_of(:data).is_at_most(Constants::NAME_MAX_LENGTH) }
      it {
        expect(repository_checklist_item).to validate_uniqueness_of(:data)
          .scoped_to(:repository_column_id).case_insensitive
      }
    end
  end
end
