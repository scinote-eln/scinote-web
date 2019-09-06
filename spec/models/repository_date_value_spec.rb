# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDateValue, type: :model do
  let(:repository_date_value) { build :repository_date_value }

  it 'is valid' do
    expect(repository_date_value).to be_valid
  end

  it 'should be of class RepositoryDateValue' do
    expect(subject.class).to eq RepositoryDateValue
  end

  describe 'Database table' do
    it { should have_db_column :data }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should have_one :repository_cell }
  end

  describe 'Validations' do
    it { should validate_presence_of :repository_cell }
    it { should validate_presence_of :data }
  end
end
