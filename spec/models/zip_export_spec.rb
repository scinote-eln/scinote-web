# frozen_string_literal: true

require 'rails_helper'

describe ZipExport, type: :model do
  let(:zip_export) { build :zip_export }

  it 'is valid' do
    expect(zip_export).to be_valid
  end

  it 'should be of class ZipExport' do
    expect(subject.class).to eq ZipExport
  end

  describe 'Database table' do
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:user).optional }
  end
end
