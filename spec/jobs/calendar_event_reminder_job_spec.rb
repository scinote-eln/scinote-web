# frozen_string_literal: true

require 'rails_helper'

describe CalendarEventReminderJob, type: :job do
  around do |example|
    Timecop.freeze(Time.utc(2030, 3, 14, 12, 0, 0)) do
      example.run
    end
  end

  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:row) do
    create :repository_row, name: 'Centrifuge A', repository: repository,
                            created_by: user, last_modified_by: user
  end

  def booking(name, start_datetime: nil, start_date: nil, reminder_sent: false)
    event = create :calendar_event, team: team, created_by: user, subject: row, name: name,
                                    start_datetime: start_datetime, start_date: start_date,
                                    end_datetime: start_datetime && start_datetime + 1.hour
    event.update_column(:reminder_sent, true) if reminder_sent
    event
  end

  let!(:starting_in_five_hours) { booking('In five hours', start_datetime: Time.current + 5.hours) }
  let!(:starting_in_twenty_three_hours) { booking('In twenty-three hours', start_datetime: Time.current + 23.hours) }
  let!(:starting_tomorrow_all_day) { booking('All day tomorrow', start_date: Date.new(2030, 3, 15)) }
  let!(:started_an_hour_ago) { booking('Started an hour ago', start_datetime: Time.current - 1.hour) }
  let!(:in_twenty_five_hours) { booking('In twenty-five hours', start_datetime: Time.current + 25.hours) }
  let!(:started_three_hours_ago) { booking('Started three hours ago', start_datetime: Time.current - 3.hours) }
  let!(:already_reminded) do
    booking('Already reminded', start_datetime: Time.current + 5.hours, reminder_sent: true)
  end

  before { allow(EquipmentBookingReminderNotification).to receive(:send_notifications) }

  it 'sends a reminder for every booking starting within the window or started within the buffer' do
    described_class.perform_now

    [starting_in_five_hours, starting_in_twenty_three_hours, starting_tomorrow_all_day, started_an_hour_ago]
      .each do |event|
      expect(EquipmentBookingReminderNotification).to have_received(:send_notifications)
        .with(hash_including(calendar_event_id: event.id))
    end
    expect(EquipmentBookingReminderNotification).to have_received(:send_notifications).exactly(4).times
  end

  it 'skips bookings outside the window, older than the buffer, or already reminded' do
    described_class.perform_now

    [in_twenty_five_hours, started_three_hours_ago, already_reminded].each do |event|
      expect(EquipmentBookingReminderNotification).not_to have_received(:send_notifications)
        .with(hash_including(calendar_event_id: event.id))
    end
  end

  it 'passes the booking details needed to render the reminder even if the booking is later deleted' do
    described_class.perform_now

    expect(EquipmentBookingReminderNotification).to have_received(:send_notifications).with(
      calendar_event_id: starting_in_five_hours.id,
      name: 'In five hours',
      start_date: nil,
      start_datetime: starting_in_five_hours.start_datetime,
      repository_row_id: row.id,
      repository_row_name: 'Centrifuge A'
    )
  end

  it 'sends nothing when no booking is due' do
    CalendarEvent.update_all(reminder_sent: true) # rubocop:disable Rails/SkipsModelValidations

    described_class.perform_now

    expect(EquipmentBookingReminderNotification).not_to have_received(:send_notifications)
  end
end
