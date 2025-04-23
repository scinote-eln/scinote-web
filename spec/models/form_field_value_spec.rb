# frozen_string_literal: true

require 'rails_helper'

describe FormFieldValue, type: :model do
  let(:form_response) { build :form_field_value }

  it 'is valid' do
    expect(form_response).to be_valid
  end

  it 'should be of class form field value' do
    expect(subject.class).to eq FormFieldValue
  end

  describe 'Database table' do
    it { should have_db_column :form_response_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :submitted_by_id }
    it { should have_db_column :submitted_at }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :latest }
    it { should have_db_column :not_applicable }
    it { should have_db_column :datetime }
    it { should have_db_column :datetime_to }
    it { should have_db_column :number }
    it { should have_db_column :number_to }
    it { should have_db_column :text }
    it { should have_db_column :selection }
    it { should have_db_column :flag }
  end

  describe 'Relations' do
    it { should belong_to(:form_response) }
    it { should belong_to(:form_field) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:submitted_by).class_name('User') }
  end
end
