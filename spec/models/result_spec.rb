# frozen_string_literal: true

require 'rails_helper'

describe Result, type: :model do
  let(:result) { build :result }

  it 'is valid' do
    expect(result).to be_valid
  end

  it 'should be of class Result' do
    expect(subject.class).to eq Result
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :my_module_id }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :archived }
    it { should have_db_column :archived_on }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :archived_by_id }
    it { should have_db_column :restored_by_id }
    it { should have_db_column :restored_on }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :my_module }
    it { should belong_to(:archived_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should belong_to(:restored_by).class_name('User').optional }
    it { should have_many :result_assets }
    it { should have_many :assets }
    it { should have_many :result_tables }
    it { should have_many :tables }
    it { should have_many :result_texts }
    it { should have_many :result_comments }
    it { should have_many :report_elements }
    it { should have_many :step_results }
    it { should have_many :steps }
  end

  describe 'Validations' do
    it do
      should validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH)
    end
  end
end
