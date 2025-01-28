# frozen_string_literal: true

require 'rails_helper'

describe FormResponse, type: :model do
  let(:form_response) { build :form_response }

  it 'is valid' do
    expect(form_response).to be_valid
  end

  it 'should be of class form field' do
    expect(subject.class).to eq FormResponse
  end

  describe 'Database table' do
    it { should have_db_column :form_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :submitted_by_id }
    it { should have_db_column :status }
    it { should have_db_column :submitted_at }
    it { should have_db_column :discarded_at }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:form) }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:submitted_by).class_name('User').optional }
  end
end
