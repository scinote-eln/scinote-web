require 'rails_helper'

describe ClientApi::NotificationsController, type: :controller, broken: true do
  login_user
  let(:notification) { create :notification }
  let(:user_notification) do
    create :user_notification,
           user: User.first,
           notification: notification
  end

  describe '#recent_notifications' do
    it 'returns a list of notifications' do
      get :recent_notifications, format: :json
      expect(response).to be_success
      expect(response).to render_template('client_api/notifications/index')
    end
  end

  describe '#unreaded_notifications_number' do
    it 'returns a number of unreaded notifications' do
      get :unread_notifications_count, format: :json
      expect(response).to be_success
      expect(response.body).to include('count')
    end
  end
end
