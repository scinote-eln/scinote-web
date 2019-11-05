# frozen_string_literal: true

require 'rails_helper'

describe UserTeam, type: :model do
  let(:user_team) { build :user_team }

  it 'is valid' do
    expect(user_team).to be_valid
  end

  it 'should be of class UserTeam' do
    expect(subject.class).to eq UserTeam
  end

  describe 'Database table' do
    it { should have_db_column :role }
    it { should have_db_column :user_id }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :assigned_by_id }
  end

  describe 'Relations' do
    it { should belong_to :user }
    it { should belong_to :team }
    it { should belong_to(:assigned_by).class_name('User').optional }
  end

  describe 'Validations' do
    it { should validate_presence_of :role }
    it { should validate_presence_of :user }
    it { should validate_presence_of :team }
  end
end
