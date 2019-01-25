# frozen_string_literal: true

require 'rails_helper'

describe Project, type: :model do
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
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:last_modified_by).class_name('User') }
    it { should belong_to(:archived_by).class_name('User') }
    it { should belong_to(:restored_by).class_name('User') }
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
      it { should validate_presence_of :visibility }
    end

    describe '#team' do
      it { should validate_presence_of :team }
    end

    describe '#name' do
      it 'should be at least 2 long and max 255 long' do
        should validate_length_of(:name)
          .is_at_least(Constants::NAME_MIN_LENGTH)
          .is_at_most(Constants::NAME_MAX_LENGTH)
      end

      it 'should be uniq per project and team' do
        first_project = create :project
        second_project = build :project,
                               name: first_project.name,
                               team: first_project.team

        expect(second_project).to_not be_valid
      end
    end
  end
end
