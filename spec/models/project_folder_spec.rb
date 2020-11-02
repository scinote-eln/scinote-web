# frozen_string_literal: true

require 'rails_helper'

describe ProjectFolder, type: :model do
  let(:project_folder) { build :project_folder }

  it 'is valid' do
    expect(project_folder).to be_valid
  end

  it 'should be of class ProjectFolder' do
    expect(subject.class).to eq ProjectFolder
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :team_id }
    it { should have_db_column :parent_folder_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to(:team) }
    it { should belong_to(:parent_folder).class_name('ProjectFolder').optional }
    it { should have_many :projects }
    it { should have_many :project_folders }
  end

  describe 'Validations' do
    describe '#name' do
      it do
        is_expected.to(validate_length_of(:name)
                         .is_at_least(Constants::NAME_MIN_LENGTH)
                         .is_at_most(Constants::NAME_MAX_LENGTH))
      end
      it do
        expect(project_folder).to validate_uniqueness_of(:name).scoped_to(:team_id).case_insensitive
      end
    end
  end
end
