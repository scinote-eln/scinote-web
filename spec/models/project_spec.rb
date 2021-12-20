# frozen_string_literal: true

require 'rails_helper'

describe Project, type: :model do
  let(:project) { build :project }

  it 'is valid' do
    expect(project).to be_valid
  end

  it 'should be of class Project' do
    expect(subject.class).to eq Project
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :visibility }
    it { should have_db_column :due_date }
    it { should have_db_column :team_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :archived }
    it { should have_db_column :archived_on }
    it { should have_db_column :created_by_id }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :archived_by_id }
    it { should have_db_column :restored_by_id }
    it { should have_db_column :restored_on }
    it { should have_db_column :experiments_order }
    it { should have_db_column :template }
  end

  describe 'Relations' do
    it { should belong_to(:team) }
    it { should belong_to(:created_by).class_name('User').optional }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should belong_to(:archived_by).class_name('User').optional }
    it { should belong_to(:restored_by).class_name('User').optional }
    it { should have_many :user_projects }
    it { should have_many :users }
    it { should have_many :experiments }
    it { should have_many :project_comments }
    it { should have_many :activities }
    it { should have_many :tags }
    it { should have_many :reports }
    it { should have_many :report_elements }
  end

  describe 'Validations' do
    describe '#visibility' do
      it { is_expected.to validate_presence_of :visibility }
    end

    describe '#team' do
      it { is_expected.to validate_presence_of :team }
    end

    describe '#name' do
      it do
        is_expected.to(validate_length_of(:name)
                         .is_at_least(Constants::NAME_MIN_LENGTH)
                         .is_at_most(Constants::NAME_MAX_LENGTH))
      end
      it do
        expect(project).to validate_uniqueness_of(:name).scoped_to(:team_id).case_insensitive
      end
    end

    describe '#project_folder_team' do
      it 'should validate equals of team and project_folder team' do
        project_folder = create(:project_folder, name: 'Folder from another team')
        project.project_folder = project_folder
        project.save

        expect(project.errors).to have_key(:project_folder)
      end
    end
  end

  describe 'after create hooks' do


    it 'grands owner permissions to project creator' do
      user = create(:user)
      project.created_by = user
      expect {
        project.save
      }.to change(UserAssignment, :count).by(1)
      user_role = project.reload.user_assignments.first.user_role
      expect(user_role.name).to eq 'Owner'
    end
  end
end
