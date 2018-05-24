require 'rails_helper'

RSpec.describe Views::Datatables::DatatablesReport, type: :model do
  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :name }
    it { should have_db_column :project_name }
    it { should have_db_column :created_by }
    it { should have_db_column :last_modified_by }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :project_archived }
    it { should have_db_column :project_visibility }
    it { should have_db_column :project_id }
    it { should have_db_column :team_id }
    it { should have_db_column :users_with_team_read_permissions }
    it { should have_db_column :users_with_project_read_permissions }
  end

  describe 'is readonly' do
    let(:team) { create :team }
    it do
      expect {
        Views::Datatables::DatatablesReport.create!(team: team)
      }.to raise_error(
        ActiveRecord::ReadOnlyRecord,
        'Views::Datatables::DatatablesReport is marked as readonly'
      )
    end
  end

  describe '#tokenize/1' do
    it 'returns an array of permission items' do
      items = [[1, [1, 2]], [2, [3, 4]]]
      tokenized = described_class.send('tokenize', items)
      expect(tokenized.first).to have_attributes(report_id: 1,
                                                 users_ids: [1, 2])
      expect(tokenized.last).to have_attributes(report_id: 2, users_ids: [3, 4])
    end
  end

  describe '#for_admin/3' do
    let!(:user) { create :user }
    let!(:user_two) { create :user, email: 'user.two@asdf.com' }
    let!(:team) { create :team }
    let!(:project) do
      create :project, created_by: user, last_modified_by: user, team: team
    end
    let!(:user_project) { create :user_project, project: project, user: user }
    let!(:team_two) { create :team }
    let!(:user_team) do
      create :user_team, team: team_two, user: user_two, role: 0
    end
    let!(:user_team) { create :user_team, team: team, user: user, role: 2 }

    let!(:project_two) do
      create :project, created_by: user_two,
                       last_modified_by: user_two,
                       team: team_two
    end
    let!(:report_one) do
      create :report, user: user,
                      team: team,
                      name: 'report one',
                      project: project
    end
    let!(:report_two) do
      create :report, user: user,
                      team: team_two,
                      project: project_two,
                      name: 'report two'
    end

    it 'returns the reports' do
      reports = team.datatables_reports.visible_by(user, team)
      expect(reports.length).to eq 1
      expect(reports.first.id).to eq report_one.id
    end
  end
end
