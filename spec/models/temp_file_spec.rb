# frozen_string_literal: true

require 'rails_helper'

describe TempFile, type: :model do
  let(:temp_file) { build :temp_file }

  it 'is valid' do
    expect(temp_file).to be_valid
  end

  it 'should be of class TempFile' do
    expect(subject.class).to eq TempFile
  end

  describe 'Database table' do
    it { should have_db_column :session_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Validations' do
    it { should validate_presence_of :session_id }
  end
end
