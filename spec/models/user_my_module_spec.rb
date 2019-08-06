# frozen_string_literal: true

require 'rails_helper'

describe UserMyModule, type: :model do
  let(:user_my_module) { build :user_my_module }

  it 'is valid' do
    expect(user_my_module).to be_valid
  end

  it 'should be of class UserMyModule' do
    expect(subject.class).to eq UserMyModule
  end

  describe 'Database table' do
    it { should have_db_column :user_id }
    it { should have_db_column :my_module_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :assigned_by_id }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :my_module }
    it { should belong_to(:assigned_by).class_name('User').optional }
  end

  describe 'Validations' do
    it { should validate_presence_of :user }
    it { should validate_presence_of :my_module }
  end
end
