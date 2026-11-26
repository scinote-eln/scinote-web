# frozen_string_literal: true

require 'rails_helper'

describe EquipmentBookingReminderNotification do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:row) do
    create :repository_row, name: 'Centrifuge A', repository: repository,
                            created_by: user, last_modified_by: user
  end
  let(:start_at) { Time.zone.parse('2030-03-14 09:30') }
  let(:event) do
    create :calendar_event, team: team, created_by: user, subject: row, name: 'Spin cycle',
                            start_datetime: start_at, end_datetime: start_at + 1.hour
  end

  def row_link(row_record)
    path = Rails.application.routes.url_helpers.repository_path(
      repository, landing_page: true, row_id: row_record.id, anchor: 'schedule-section'
    )
    "<a href=\"#{path}\">#{row_record.name}</a>"
  end

  describe '.subtype' do
    it 'is the equipment_booking_reminder subtype' do
      expect(described_class.subtype).to eq :equipment_booking_reminder
    end
  end

  describe '#subject' do
    it 'returns the calendar event when it exists' do
      expect(described_class.with(calendar_event_id: event.id).subject).to eq event
    end

    it 'returns a placeholder built from the stored params when the event is gone' do
      stored = { calendar_event_id: nil, name: 'Spin cycle', start_date: nil, start_datetime: start_at,
                 repository_row_id: row.id, repository_row_name: row.name }

      placeholder = described_class.with(stored).subject

      expect(placeholder).to be_a NonExistantRecord
      expect(placeholder.name).to eq 'Spin cycle'
      expect(placeholder.start_datetime).to eq start_at
      expect(placeholder.subject).to eq row
    end
  end

  describe '#title' do
    let(:date_text) { I18n.l(start_at, format: :full_date) }

    it 'links the row and states the start date and time of the booking' do
      expected = "Your event Spin cycle for #{row_link(row)} scheduled for #{date_text} 09:30 " \
                 'is happening within 24 hours!'

      expect(described_class.with(calendar_event_id: event.id).title).to eq expected
    end

    it 'omits the time for an all-day booking' do
      event.update!(start_datetime: nil, end_datetime: nil, start_date: Date.new(2030, 3, 14), end_date: Date.new(2030, 3, 14))
      date_only = I18n.l(Date.new(2030, 3, 14), format: :full_date)
      expected = "Your event Spin cycle for #{row_link(row)} scheduled for #{date_only} is happening within 24 hours!"

      expect(described_class.with(calendar_event_id: event.id).title).to eq expected
    end

    it 'shows the row name without a link when the row has been deleted' do
      stored = { calendar_event_id: nil, name: 'Spin cycle', start_date: nil, start_datetime: start_at,
                 repository_row_id: nil, repository_row_name: 'Centrifuge B' }
      expected = "Your event Spin cycle for Centrifuge B scheduled for #{date_text} 09:30 " \
                 'is happening within 24 hours!'

      expect(described_class.with(stored).title).to eq expected
    end
  end

  describe 'delivery' do
    it 'notifies the event creator and marks the event reminder as sent' do
      event.update_column(:reminder_sent, false)

      described_class.send_notifications({ calendar_event_id: event.id, name: event.name,
                                           start_date: nil, start_datetime: start_at,
                                           repository_row_id: row.id, repository_row_name: row.name },
                                         later: false)

      expect(Notification.where(recipient: user, type: 'EquipmentBookingReminderNotification').count).to eq 1
      expect(event.reload.reminder_sent).to be true
    end
  end
end
