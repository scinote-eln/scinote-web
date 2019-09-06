# frozen_string_literal: true

require 'rails_helper'

describe ResultComment, type: :model do
  let(:result_comment) { build :result_comment }

  it 'is valid' do
    expect(result_comment).to be_valid
  end

  it 'should be of class ResultComment' do
    expect(subject.class).to eq ResultComment
  end

  describe 'Database table' do
    it { should have_db_column :message }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :type }
    it { should have_db_column :associated_id }
  end

  describe 'Relations' do
    it { should belong_to :result }
  end

  describe 'Validations' do
    it { should validate_presence_of :result }
  end
end
