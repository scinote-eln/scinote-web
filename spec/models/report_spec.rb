# frozen_string_literal: true

require 'rails_helper'

describe Report, type: :model do
  let(:report) { build :report }

  it 'is valid' do
    expect(report).to be_valid
  end

  it 'should be of class Report' do
    expect(subject.class).to eq Report
  end

  describe 'Database table' do
    it { should have_db_column :name }
    it { should have_db_column :description }
    it { should have_db_column :project_id }
    it { should have_db_column :user_id }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :last_modified_by_id }
    it { should have_db_column :team_id }
  end

  describe 'Relations' do
    it { should belong_to :project }
    it { should belong_to :user }
    it { should belong_to :team }
    it { should belong_to(:last_modified_by).class_name('User').optional }
    it { should have_many :report_elements }
  end

  describe 'Validations' do
    it do
      should validate_length_of(:description)
        .is_at_most(Constants::TEXT_MAX_LENGTH)
    end
    it do
      should validate_length_of(:name)
        .is_at_least(Constants::NAME_MIN_LENGTH)
        .is_at_most(Constants::NAME_MAX_LENGTH)
    end
  end

  describe '.default_repository_columns' do
    it 'maps the built-in column ids to their translated names' do
      expect(described_class.default_repository_columns).to eq(
        '-1': I18n.t('repositories.table.id'),
        '-2': I18n.t('repositories.table.row_name'),
        '-3': I18n.t('repositories.table.added_on'),
        '-4': I18n.t('repositories.table.added_by')
      )
    end
  end

  describe '.generate_whole_project_report' do
    let(:user) { create :user }
    let(:team) { create :team, created_by: user }
    let(:project) { create :project, team: team, created_by: user }
    let!(:experiment) { create :experiment, project: project, created_by: user }
    let!(:my_module) { create :my_module, experiment: experiment, created_by: user }
    let!(:repository) { create :repository, team: team, created_by: user }
    let!(:repository_row) { create :repository_row, repository: repository, created_by: user }

    before do
      user.update!(current_team_id: team.id)
      create :mm_repository_row, repository_row: repository_row, my_module: my_module, assigned_by: user
      create_user_assignment(team, UserRole.find_by(name: I18n.t('user_roles.predefined.owner')), user)
    end

    it 'builds a saved report for the user and project with a generated name' do
      report = described_class.generate_whole_project_report(project, user, team)

      expect(report).to be_persisted
      expect(report).to have_attributes(project: project, user: user, team: team, last_modified_by: user)
      expect(report.name).to match(/\A\h{20}\z/)
    end

    it 'puts every task of the project and the readable inventories into the report settings' do
      report = described_class.generate_whole_project_report(project, user, team)

      expect(report.settings['task']['repositories']).to eq [repository.id]
      expect(report.report_elements.where(type_of: :experiment).map(&:experiment)).to eq [experiment]
      expect(report.report_elements.where(type_of: :my_module).map(&:my_module)).to eq [my_module]
    end
  end
end
