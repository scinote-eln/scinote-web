# frozen_string_literal: true

require 'rails_helper'

describe SystemNotificationsController, type: :controller do
  login_user
  render_views
  let(:user) { subject.current_user }

  describe 'Methods' do
    let(:notifcation_one) { create :system_notification }
    let(:notifcation_two) { create :system_notification, title: 'Special one' }
    before do
      create :user_system_notification,
             user: user,
             system_notification: notifcation_one
      create :user_system_notification,
             user: user,
             system_notification: notifcation_two
    end

    it '#show return right result format' do
      params = {
        id: user.user_system_notifications.first.system_notification_id
      }
      get :show, format: :json, params: params
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include('id', 'modal_title', 'modal_body')
    end

    it '#mark_as_seen correctly set seen_at' do
      params = {
        notifications: user.user_system_notifications
                           .map(&:system_notification_id).to_s
      }
      get :mark_as_seen, format: :json, params: params
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['result']).to eq 'ok'
      expect(user.user_system_notifications.where(seen_at: nil).count).to eq 0
    end

    it '#mark_as_read correctly set read_at' do
      params = {
        id: user.user_system_notifications.first.system_notification_id
      }
      get :mark_as_read, format: :json, params: params
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['result']).to eq 'ok'
      expect(user.user_system_notifications.where(read_at: nil).count).to eq 1
    end

    it '#unseen_counter return right result' do
      get :unseen_counter, format: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['notificationNmber']).to eq 2
    end

    it '#index check next page link' do
      notifications = create_list :system_notification, 50
      notifications.each do |i|
        create :user_system_notification,
               user: user,
               system_notification: i
      end
      get :index, format: :json
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['more_url']).to include('system_notifications.json?page=2')
    end
  end
end
