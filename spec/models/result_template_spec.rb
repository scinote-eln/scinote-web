# frozen_string_literal: true

require 'rails_helper'

describe ResultTemplate, type: :model do
  let(:result) { build :result_template }

  it 'is valid' do
    expect(result).to be_valid
  end

  it 'should be of class ResultTemplate' do
    expect(subject.class).to eq ResultTemplate
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :protocol_id }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :last_modified_by_id }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :protocol }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should have_many :result_assets }
    it { should have_many :assets }
    it { should have_many :result_tables }
    it { should have_many :tables }
    it { should have_many :result_texts }
  end

  describe 'Validations' do
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
  end
end
