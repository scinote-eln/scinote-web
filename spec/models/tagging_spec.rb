# frozen_string_literal: true

require 'rails_helper'

describe Tagging, type: :model do
  let(:tagging) { build :tagging }

  it 'is valid' do
    expect(tagging).to be_valid
  end

  it 'should be of class Tagging' do
    expect(subject.class).to eq Tagging
  end

  describe 'Database table' do
    it { should have_db_column :taggable_type }
    it { should have_db_column :taggable_id }
    it { should have_db_column :tag_id }
    it { should have_db_column :created_by_id }
  end

  describe 'Relations' do
    it { should belong_to(:taggable) }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:tag) }
  end
end
