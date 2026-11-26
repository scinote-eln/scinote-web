# frozen_string_literal: true

require 'rails_helper'

describe UserNotificationsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:json) { JSON.parse(response.body) }

  def notification_for(recipient, attrs = {})
    Notification.create!(
      { recipient: recipient,
        type: 'GeneralNotification',
        params: { title: 'Title', message: 'Message', subject_class: 'User', subject_id: recipient.id } }.merge(attrs)
    )
  end

  describe 'GET index' do
    let!(:unread) { notification_for(user, read_at: nil, created_at: 2.hours.ago) }
    let!(:read) { notification_for(user, read_at: 1.hour.ago, created_at: 1.hour.ago) }
    let!(:hidden) do
      notification_for(user, read_at: nil, params: { title: 'x', message: 'x', hide_in_app: true })
    end
    let!(:foreign) { notification_for(create(:user), read_at: nil) }

    it 'returns own in-app notifications, newest first' do
      get :index, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['data'].map { |n| n['id'].to_i }).to eq [read.id, unread.id]
    end

    it 'serializes the notification attributes' do
      get :index, params: { tab: 'unread' }, format: :json

      attrs = json['data'].first['attributes']
      expect(attrs).to include('title' => 'Title', 'message' => 'Message', 'checked' => false)
      expect(attrs['toggle_read_url']).to eq toggle_read_user_notification_path(unread)
    end

    it 'filters the read tab' do
      get :index, params: { tab: 'read' }, format: :json

      expect(json['data'].map { |n| n['id'].to_i }).to eq [read.id]
    end

    it 'filters the unread tab' do
      get :index, params: { tab: 'unread' }, format: :json

      expect(json['data'].map { |n| n['id'].to_i }).to eq [unread.id]
    end

    it 'paginates' do
      stub_const('Constants::INFINITE_SCROLL_LIMIT', 1)

      get :index, params: { page: { number: 2 } }, format: :json

      expect(json['data'].map { |n| n['id'].to_i }).to eq [unread.id]
    end
  end

  describe 'POST mark_all_read' do
    it 'marks all in-app notifications of the user as read' do
      a = notification_for(user, read_at: nil)
      foreign = notification_for(create(:user), read_at: nil)
      allow(Notification).to receive(:broadcast_unseen_count_to)

      post :mark_all_read, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['success']).to be true
      expect(a.reload.read_at).to be_present
      expect(foreign.reload.read_at).to be_nil
      expect(Notification).to have_received(:broadcast_unseen_count_to).with(user)
    end
  end

  describe 'POST toggle_read' do
    let!(:notification) { notification_for(user, read_at: nil) }

    it 'marks the notification as read' do
      allow(Notification).to receive(:broadcast_unseen_count_to)

      post :toggle_read, params: { id: notification.id, mark_as_read: true }, format: :json

      expect(response).to have_http_status(:ok)
      expect(notification.reload.read_at).to be_present
      expect(json['data']['attributes']['checked']).to be true
      expect(Notification).to have_received(:broadcast_unseen_count_to).with(user)
    end

    it 'marks the notification as unread' do
      notification.update!(read_at: 1.hour.ago)
      allow(Notification).to receive(:broadcast_unseen_count_to)

      post :toggle_read, params: { id: notification.id }, format: :json

      expect(notification.reload.read_at).to be_nil
    end

    it 'returns 404 for notifications of other users' do
      foreign = notification_for(create(:user))
      allow(Notification).to receive(:broadcast_unseen_count_to)

      expect do
        post :toggle_read, params: { id: foreign.id }, format: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
