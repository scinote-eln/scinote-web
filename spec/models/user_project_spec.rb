# frozen_string_literal: true

require 'rails_helper'

describe UserProject, type: :model do
  let(:user_project_without_role) { build :user_project }
  let(:user_project) { build :user_project, :owner }


  it 'is valid with role' do
    expect(user_project).to be_valid
  end

  it 'should be of class UserProject' do
    expect(subject.class).to eq UserProject
  end

  describe 'Database table' do
    it { should have_db_column :user_id }
    it { should have_db_column :project_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :assigned_by_id }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :project }
    it { should belong_to(:assigned_by).class_name('User').optional }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of :user }
    it { should validate_presence_of :project }
  end
end
