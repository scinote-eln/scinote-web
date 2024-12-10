# frozen_string_literal: true

require 'rails_helper'

describe Form, type: :model do
  let(:form) { build :form }

  it 'is valid' do
    expect(form).to be_valid
  end

  it 'should be of class Form' do
    expect(subject.class).to eq Form
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :team_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :parent_id }
    it { should have_db_column :published_by_id }
    it { should have_db_column :published_on }
    it { should have_db_column :archived }
    it { should have_db_column :archived_on }
    it { should have_db_column :archived_by_id }
    it { should have_db_column :restored_by_id }
    it { should have_db_column :restored_on }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:team) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to(:parent).class_name('Form').optional }
    it { should belong_to(:archived_by).class_name('User').optional }
    it { should belong_to(:restored_by).class_name('User').optional }
    it { should have_many :form_fields }
  end

  describe 'Validations' do
    describe '#name' do
      it do
        is_expected.to(validate_length_of(:name).is_at_least(Constants::NAME_MIN_LENGTH).is_at_most(Constants::NAME_MAX_LENGTH))
      end
    end
    describe '#description' do
      it do
        is_expected.to(validate_length_of(:description).is_at_most(Constants::NAME_MAX_LENGTH))
      end
    end
  end
end
