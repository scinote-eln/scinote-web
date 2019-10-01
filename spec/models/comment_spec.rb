# frozen_string_literal: true

require 'rails_helper'

describe Comment, type: :model do
  let(:comment) { build :comment }

  it 'is valid' do
    expect(comment).to be_valid
  end

  it 'should be of class Comment' do
    expect(subject.class).to eq Comment
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :message }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :type }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :associated_id }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to(:last_modified_by).class_name('User').optional }
  end

  describe 'Validations' do
    it { should validate_presence_of :message }
    it { should validate_length_of(:message).is_at_most(Constants::TEXT_MAX_LENGTH) }
    it { should validate_presence_of :user }
  end
end
