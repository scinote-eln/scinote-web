# frozen_string_literal: true

require 'rails_helper'

describe ExperimentDueDateReminderJob, type: :job do
  around do |example|
    Timecop.freeze(Time.utc(2025, 4, 23, 0, 0, 0)) do
      example.run
    end
  end

  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }

  let!(:project) { create(:project, team: team, created_by: user, default_public_user_role_id: team_assignment.user_role.id) }
  let!(:project_archived) { create(:project, team: team, created_by: user, archived: true, default_public_user_role_id: team_assignment.user_role.id) }

  let!(:experiment_overdue) { create(:experiment, project: project, created_by: user, due_date: Date.parse('25-4-2025')) }
  let!(:experiment_due_in_one_day) { create(:experiment, project: project, created_by: user, due_date: Date.parse('24-4-2025')) }
  let!(:experiment_on_due_date) { create(:experiment, project: project, created_by: user, due_date: Date.parse('23-4-2025')) }
  let!(:experiment_before_due_date) { create(:experiment, project: project, created_by: user, due_date: Date.parse('22-4-2025')) }
  let!(:experiment_archived) { create(:experiment, project: project, created_by: user, archived: true, due_date: Date.parse('24-4-2025')) }
  let!(:experiment_within_archived_project) { create(:experiment, project: project_archived, created_by: user, archived: true, due_date: Date.parse('24-4-2025')) }
  let!(:experiment_notifcation_sent) do 
    pr = create(:experiment, project: project, created_by: user, due_date: Date.parse('24-4-2025'))
    pr.update_column(:due_date_notification_sent, true)
    pr
  end

  describe '#experiments_due' do
    it "returns experiments that are due with a one day before due" do
      values = described_class.new.send(:experiments_due)
      expect(values).to_not include(experiment_overdue)
      expect(values).to include(experiment_due_in_one_day)
      expect(values).to_not include(experiment_on_due_date)
      expect(values).to_not include(experiment_before_due_date)
    end

    it "do not return archived experiments" do
      values = described_class.new.send(:experiments_due)
      expect(values).to_not include(experiment_archived)
      expect(values).to_not include(experiment_within_archived_project)
    end

    it "do not return already sent experiment notifications" do
      values = described_class.new.send(:experiments_due)
      expect(values).to_not include(experiment_notifcation_sent)
    end
  end
end
