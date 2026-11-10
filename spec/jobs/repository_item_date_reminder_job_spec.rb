# frozen_string_literal: true

require 'rails_helper'

describe RepositoryItemDateReminderJob, type: :job do
  around do |example|
    Timecop.freeze(Time.utc(2025, 1, 15, 0, 0, 0)) do
      example.run
    end
  end

  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:repository) { create :repository, team: team, created_by: user }

  let!(:date_column_with_reminder) do
    create :repository_column, repository: repository,
                               created_by: user,
                               name: 'Custom items',
                               data_type: 'RepositoryDateValue',
                               metadata: {"reminder_unit"=>"86400", "reminder_value"=>"5", "reminder_message"=>""}
  end

  let!(:repository_date_value_due) do
    row = create :repository_row, name: "row 1",
                                  repository: repository,
                                  created_by: user,
                                  last_modified_by: user

    create(
      :repository_date_value,
      data: Date.parse('20-1-2025'),
      repository_cell_attributes: { repository_row: row, repository_column: date_column_with_reminder }
    )
  end

  let!(:repository_date_value_due_outside_buffer) do
    row = create :repository_row, name: "row 1",
                                  repository: repository,
                                  created_by: user,
                                  last_modified_by: user

    create(
      :repository_date_value,
      data: Date.parse('15-1-2025') - (RepositoryItemDateReminderJob::BUFFER_DAYS + 1).days,
      repository_cell_attributes: { repository_row: row, repository_column: date_column_with_reminder }
    )
  end

  let!(:repository_date_value_due_inside_buffer) do
    row = create :repository_row, name: "row 1",
                                  repository: repository,
                                  created_by: user,
                                  last_modified_by: user

    create(
      :repository_date_value,
      data: Date.parse('15-1-2025') - (RepositoryItemDateReminderJob::BUFFER_DAYS - 1).days,
      repository_cell_attributes: { repository_row: row, repository_column: date_column_with_reminder }
    )
  end

  let!(:repository_date_value_not_due) do
    row = create :repository_row, name: "row 1",
                                  repository: repository,
                                  created_by: user,
                                  last_modified_by: user

    create(
      :repository_date_value,
      data: Date.parse('10-10-2025'),
      repository_cell_attributes: { repository_row: row, repository_column: date_column_with_reminder }
    )
  end

  describe '#repository_values_due' do
    it "returns repository values that are due with a #{RepositoryItemDateReminderJob::BUFFER_DAYS} day buffer" do
      values = described_class.new.send(:repository_values_due, RepositoryDateValue,  Date.current)
      expect(values).to include(repository_date_value_due)
      expect(values).to_not include(repository_date_value_not_due)
      expect(values).to include(repository_date_value_due_inside_buffer)
      expect(values).to_not include(repository_date_value_due_outside_buffer)
    end
  end

  describe '#perform' do
    it 'sends a notification for each due value' do
      allow(RepositoryItemDateNotification).to receive(:send_notifications)

      described_class.perform_now

      [repository_date_value_due, repository_date_value_due_inside_buffer].each do |value|
        expect(RepositoryItemDateNotification).to have_received(:send_notifications).with(
          hash_including(repository_date_value_id: value.id,
                         repository_row_id: value.repository_cell.repository_row_id,
                         repository_column_id: date_column_with_reminder.id,
                         repository_column_name: 'Custom items',
                         reminder_unit: '86400',
                         reminder_value: '5')
        )
      end
      expect(RepositoryItemDateNotification).to have_received(:send_notifications).twice
    end

    it 'ignores values of archived rows' do
      repository_date_value_due.repository_cell.repository_row.update_columns(archived: true)
      allow(RepositoryItemDateNotification).to receive(:send_notifications)

      described_class.perform_now

      expect(RepositoryItemDateNotification).to have_received(:send_notifications).once
    end

    it 'ignores values that were already notified' do
      repository_date_value_due.update_columns(notification_sent: true)
      repository_date_value_due_inside_buffer.update_columns(notification_sent: true)
      expect(RepositoryItemDateNotification).not_to receive(:send_notifications)

      described_class.perform_now
    end
  end
end
