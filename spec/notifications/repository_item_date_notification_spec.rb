# frozen_string_literal: true

require 'rails_helper'

describe RepositoryItemDateNotification do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:row) do
    create :repository_row, name: 'Reagent batch 7', repository: repository,
                            created_by: user, last_modified_by: user
  end
  let(:day_column) do
    create :repository_column, repository: repository, created_by: user, name: 'Expiry',
                               data_type: 'RepositoryDateValue',
                               metadata: { 'reminder_unit' => '86400', 'reminder_value' => '5', 'reminder_message' => '' }
  end
  let(:date_value) do
    create :repository_date_value, data: Date.new(2030, 1, 1),
                                   repository_cell_attributes: { repository_row: row, repository_column: day_column }
  end
  let(:params) do
    { repository_row_id: row.id, repository_row_name: row.name, reminder_unit: '86400', reminder_value: '5' }
  end

  describe '.subtype' do
    it 'is the item_date_reminder subtype' do
      expect(described_class.subtype).to eq :item_date_reminder
    end
  end

  describe '#title' do
    def title_for(overrides)
      described_class.with(params.merge(overrides)).title
    end

    it 'names the row and the reminder interval in days' do
      expect(title_for({})).to eq 'Date reminder for Reagent batch 7 is coming up in 5 days.'
    end

    it 'uses the singular unit when the reminder value is one' do
      expect(title_for(reminder_value: '1')).to eq 'Date reminder for Reagent batch 7 is coming up in 1 day.'
    end

    it 'converts a week interval' do
      expect(title_for(reminder_unit: '604800', reminder_value: '2'))
        .to eq 'Date reminder for Reagent batch 7 is coming up in 2 weeks.'
    end

    it 'converts a month interval' do
      expect(title_for(reminder_unit: '2419200', reminder_value: '1'))
        .to eq 'Date reminder for Reagent batch 7 is coming up in 1 month.'
    end

    it 'raises for an unknown reminder unit' do
      expect { title_for(reminder_unit: '3600') }
        .to raise_error(ArgumentError, 'Unrecognized time unit for seconds value: 3600')
    end

    it 'uses the stored row name when the repository row no longer exists' do
      expect(title_for(repository_row_id: nil, repository_row_name: 'Deleted reagent'))
        .to eq 'Date reminder for Deleted reagent is coming up in 5 days.'
    end
  end

  describe '#subject' do
    it 'returns the repository row when it exists' do
      expect(described_class.with(params).subject).to eq row
    end

    it 'returns a placeholder carrying the stored name when the row is gone' do
      placeholder = described_class.with(params.merge(repository_row_id: nil, repository_row_name: 'Deleted reagent')).subject

      expect(placeholder).to be_a NonExistantRecord
      expect(placeholder.name).to eq 'Deleted reagent'
    end
  end

  describe 'delivery' do
    it 'delivers an in-app notification to users who can update rows and marks the date value as notified' do
      described_class.send_notifications(
        params.merge(repository_date_value_id: date_value.id), later: false
      )

      expect(Notification.where(recipient: user, type: 'RepositoryItemDateNotification').count).to eq 1
      expect(date_value.reload.notification_sent).to be true
    end

    it 'marks the date time value as notified when a date time reminder is delivered' do
      date_time_column = create :repository_column, repository: repository, created_by: user, name: 'Start',
                                                    data_type: 'RepositoryDateTimeValue',
                                                    metadata: { 'reminder_unit' => '86400', 'reminder_value' => '1' }
      date_time_value = create :repository_date_time_value, data: DateTime.new(2030, 1, 1, 9, 0, 0),
                                                            repository_cell_attributes: {
                                                              repository_row: row,
                                                              repository_column: date_time_column
                                                            }

      described_class.send_notifications(
        params.merge(repository_date_time_value_id: date_time_value.id), later: false
      )

      expect(date_time_value.reload.notification_sent).to be true
    end
  end
end
