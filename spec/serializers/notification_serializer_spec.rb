# frozen_string_literal: true

require 'rails_helper'

describe NotificationSerializer do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:routes) { Rails.application.routes.url_helpers }
  let(:created_at) { Time.zone.parse('2030-03-14 09:30') }
  let(:params) do
    { title: 'Experiment is due', message: 'Please review it', subject_class: 'Experiment', subject_id: experiment.id }
  end

  def build_notification(attrs = {})
    Notification.create!({ recipient: user, type: 'GeneralNotification', params: params,
                           read_at: nil, created_at: created_at }.merge(attrs))
  end

  def serialize(notification)
    described_class.new(notification.reload).attributes
  end

  it 'exposes the title, message and type of the notification' do
    notification = build_notification
    attrs = serialize(notification)

    expect(attrs).to include(id: notification.id, title: 'Experiment is due', message: 'Please review it',
                             type: 'GeneralNotification')
  end

  it 'formats created_at with the full date and time' do
    attrs = serialize(build_notification)

    expect(attrs[:created_at]).to eq I18n.l(created_at, format: :full)
    expect(attrs[:created_at]).to end_with('09:30')
  end

  it 'links the toggle read endpoint of the notification' do
    notification = build_notification

    expect(serialize(notification)[:toggle_read_url]).to eq routes.toggle_read_user_notification_path(notification)
  end

  it 'is unchecked while the notification is unread' do
    expect(serialize(build_notification)[:checked]).to be false
  end

  it 'is checked once the notification has been read' do
    notification = build_notification(read_at: Time.zone.parse('2030-03-15 10:00'))

    expect(serialize(notification)[:checked]).to be true
  end

  it 'marks notifications created today as today' do
    notification = build_notification(created_at: Time.zone.now)

    expect(serialize(notification)[:today]).to be true
  end

  it 'does not mark older notifications as today' do
    notification = build_notification(created_at: 2.days.ago)

    expect(serialize(notification)[:today]).to be false
  end

  describe 'breadcrumbs' do
    it 'lists the subject hierarchy from the team down to the subject' do
      breadcrumbs = serialize(build_notification)[:breadcrumbs]

      expect(breadcrumbs.map { |crumb| crumb[:name] }).to eq [team.name, project.name, experiment.name]
      expect(breadcrumbs.last[:url]).to eq routes.my_modules_experiment_path(experiment)
    end

    it 'anchors the subject link to the schedule section for a booking activity' do
      activity = create :activity, subject: experiment, owner: user, team: team,
                                   values: { 'message_items' => { 'calendar_event_id' => 1 } }
      notification = build_notification(params: params.merge(activity_id: activity.id))

      expect(serialize(notification)[:breadcrumbs].last[:url]).to eq(
        routes.my_modules_experiment_path(experiment, anchor: 'schedule-section')
      )
    end

    it 'returns no breadcrumbs when the subject no longer exists' do
      notification = build_notification(params: params.merge(subject_class: 'Experiment', subject_id: -1))

      expect(serialize(notification)[:breadcrumbs]).to eq []
    end
  end

  describe '#anchor' do
    it 'is nil for a regular notification' do
      expect(described_class.new(build_notification).anchor).to be_nil
    end

    it 'is the schedule section for an equipment booking reminder' do
      notification = build_notification(
        type: 'EquipmentBookingReminderNotification',
        params: { calendar_event_id: 1, name: 'Spin cycle', repository_row_name: 'Centrifuge A' }
      )

      pending 'bug: equipment booking reminder notifications never get the schedule-section anchor'
      expect(described_class.new(notification).anchor).to eq 'schedule-section'
    end
  end
end
