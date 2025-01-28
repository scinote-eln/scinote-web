# frozen_string_literal: true

require 'rails_helper'

describe FormField, type: :model do
  let(:form_field) { build :form_field }

  it 'is valid' do
    expect(form_field).to be_valid
  end

  it 'should be of class form field' do
    expect(subject.class).to eq FormField
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :form_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :position }
    it { should have_db_column :data }
    it { should have_db_column :required }
    it { should have_db_column :allow_not_applicable }
    it { should have_db_column :uid }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:form) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
  end

  describe 'Validations' do
    it { should validate_presence_of :position }
    describe '#name' do
      it do
        is_expected.to(validate_length_of(:name).is_at_least(Constants::NAME_MIN_LENGTH).is_at_most(Constants::NAME_MAX_LENGTH))
      end
    end
    describe '#description' do
      it do
        is_expected.to(validate_length_of(:description).is_at_most(Constants::TEXT_MAX_LENGTH))
      end
    end
  end
end
