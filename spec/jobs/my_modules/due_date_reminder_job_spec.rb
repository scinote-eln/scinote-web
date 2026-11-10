# frozen_string_literal: true

require 'rails_helper'

describe MyModules::DueDateReminderJob, type: :job do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:now) { Time.utc(2025, 4, 23, 10, 0, 0) }

  def build_task(due_date)
    create :my_module, experiment: experiment, created_by: user, due_date: due_date
  end

  it 'notifies only uncompleted tasks due within the next day that were not notified yet' do
    Timecop.freeze(now) do
      due_soon = build_task(now + 5.hours)
      build_task(now + 3.days)
      build_task(now - 1.hour)
      completed = build_task(now + 5.hours)
      completed.update_columns(state: 'completed')
      notified = build_task(now + 5.hours)
      notified.update_columns(due_date_notification_sent: true)

      expect(TaskDueDateNotification).to receive(:send_notifications).once.with({ my_module_id: due_soon.id })

      described_class.perform_now
    end
  end

  it 'does nothing when no task is due' do
    Timecop.freeze(now) do
      build_task(now + 10.days)
      expect(TaskDueDateNotification).not_to receive(:send_notifications)

      described_class.perform_now
    end
  end
end
