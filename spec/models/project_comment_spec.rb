# frozen_string_literal: true

require 'rails_helper'

describe ProjectComment, type: :model do
  let(:project_comment) { build :project_comment }

  it 'is valid' do
    expect(project_comment).to be_valid
  end

  it 'should be of class MyModuleTag' do
    expect(subject.class).to eq ProjectComment
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :message }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :type }
    it { should have_db_column :associated_id }
  end

  describe 'Relations' do
    it { should belong_to(:project).with_foreign_key('associated_id') }
  end

  describe 'Validations' do
    it { should validate_presence_of :project }
  end
end
