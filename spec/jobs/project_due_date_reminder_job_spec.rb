# frozen_string_literal: true

require 'rails_helper'

describe ProjectDueDateReminderJob, type: :job do
  around do |example|
    Timecop.freeze(Time.utc(2025, 4, 23, 0, 0, 0)) do
      example.run
    end
  end

  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }

  let!(:project_overdue) { create(:project, team: team, created_by: user, default_public_user_role_id: team_assignment.user_role.id, due_date: Date.parse('25-4-2025')) }
  let!(:project_due_in_one_day) { create(:project, team: team, created_by: user, default_public_user_role_id: team_assignment.user_role.id, due_date: Date.parse('24-4-2025')) }
  let!(:project_on_due_date) { create(:project, team: team, created_by: user, default_public_user_role_id: team_assignment.user_role.id, due_date: Date.parse('23-4-2025')) }
  let!(:project_before_due_date) { create(:project, team: team, created_by: user, default_public_user_role_id: team_assignment.user_role.id, due_date: Date.parse('22-4-2025')) }
  let!(:project_archived) { create(:project, team: team, created_by: user, archived: true, default_public_user_role_id: team_assignment.user_role.id, due_date: Date.parse('24-4-2025')) }
  let!(:project_notifcation_sent) do 
    pr = create(:project, team: team, created_by: user, default_public_user_role_id: team_assignment.user_role.id, due_date: Date.parse('24-4-2025'))
    pr.update_column(:due_date_notification_sent, true)
    pr
  end

  describe '#projects_due' do
    it "returns projects that are due with a one day before due" do
      values = described_class.new.send(:projects_due)
      expect(values).to_not include(project_overdue)
      expect(values).to include(project_due_in_one_day)
      expect(values).to_not include(project_on_due_date)
      expect(values).to_not include(project_before_due_date)
    end

    it "do not return archived projects" do
      values = described_class.new.send(:projects_due)
      expect(values).to_not include(project_archived)
    end

    it "do not return already sent project notifications" do
      values = described_class.new.send(:projects_due)
      expect(values).to_not include(project_notifcation_sent)
    end
  end
end
