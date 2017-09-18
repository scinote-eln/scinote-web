require 'rails_helper'

describe ClientApi::Users::UsersController, type: :controller do
  login_user

  before do
    @user = User.first
  end

  describe 'GET current_user_info' do
    it 'responds successfully' do
      get :current_user_info, format: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST change_password' do
    it 'responds successfully' do
      post :change_password,
           params: { user: { password: 'secretPassword'} },
           format: :json

      expect(response).to have_http_status(:ok)
    end

    it 'changes password' do
      expect(@user.valid_password?('secretPassword')).to eq(false)
      post :change_password,
           params: { user: { password: 'secretPassword'} },
           format: :json

      expect(@user.reload.valid_password?('secretPassword')).to eq(true)
    end

    it 'does not change short password' do
      expect(@user.valid_password?('pass')).to eq(false)
      post :change_password,
           params: { user: { password: 'pass'} },
           format: :json

      expect(@user.reload.valid_password?('pass')).to eq(false)
    end
  end

  describe 'POST change_timezone' do
    it 'responds successfully' do
      user = User.first
      expect(user.time_zone).to eq('UTC')
      post :change_timezone, params: { timezone: 'Pacific/Fiji' }, format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes timezone' do
      user = User.first
      expect(user.time_zone).to eq('UTC')
      post :change_timezone, params: { timezone: 'Pacific/Fiji' }, format: :json
      expect(user.reload.time_zone).to eq('Pacific/Fiji')
    end
  end

  describe 'POST change_initials' do
    it 'responds successfully' do
      post :change_initials, params: { initials: 'TD' }, format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'responds successfully' do
      user = User.first
      expect(user.initials).not_to eq('TD')
      post :change_initials, params: { initials: 'TD' }, format: :json
      expect(user.reload.initials).to eq('TD')
    end
  end

  describe 'POST change_system_notification_email' do
    it 'responds successfully' do
      post :change_system_notification_email,
           params: { status: false },
           format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes notification from false => true' do
      user = User.first
      user.system_message_notification_email = false
      user.save

      post :change_system_notification_email,
           params: { status: true },
           format: :json
      expect(user.reload.system_message_notification_email).to eq(true)
    end

    it 'changes notification from true => false' do
      user = User.first
      user.system_message_notification_email = true
      user.save

      post :change_system_notification_email,
           params: { status: false },
           format: :json
      expect(user.reload.system_message_notification_email).to eq(false)
    end
  end

  describe 'POST change_recent_notification_email' do
    it 'responds successfully' do
      post :change_recent_notification_email,
           params: { status: false },
           format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes notification from false => true' do
      user = User.first
      user.recent_notification_email = false
      user.save

      post :change_recent_notification_email,
           params: { status: true },
           format: :json
      expect(user.reload.recent_notification_email).to eq(true)
    end

    it 'changes notification from true => false' do
      user = User.first
      user.recent_notification_email = true
      user.save

      post :change_recent_notification_email,
           params: { status: false },
           format: :json
      expect(user.reload.recent_notification_email).to eq(false)
    end
  end

  describe 'POST change_recent_notification' do
    it 'responds successfully' do
      post :change_recent_notification, params: { status: false }, format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes notification from false => true' do
      user = User.first
      user.recent_notification = false
      user.save

      post :change_recent_notification, params: { status: true }, format: :json
      expect(user.reload.recent_notification).to eq(true)
    end

    it 'changes notification from true => false' do
      user = User.first
      user.recent_notification = true
      user.save

      post :change_recent_notification, params: { status: false }, format: :json
      expect(user.reload.recent_notification).to eq(false)
    end
  end

  describe 'POST change_assignements_notification_email' do
    it 'responds successfully' do
      post :change_assignements_notification_email,
           params: { status: false },
           format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes notification from false => true' do
      user = User.first
      user.assignments_notification_email = false
      user.save

      post :change_assignements_notification_email,
           params: { status: true },
           format: :json
      expect(user.reload.assignments_notification_email).to eq(true)
    end

    it 'changes notification from true => false' do
      user = User.first
      user.assignments_notification_email = true
      user.save

      post :change_assignements_notification_email,
           params: { status: false },
           format: :json
      expect(user.reload.assignments_notification_email).to eq(false)
    end
  end

  describe 'POST change_assignements_notification' do
    it 'responds successfully' do
      post :change_assignements_notification,
           params: { status: false },
           format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes notification from false => true' do
      user = User.first
      user.assignments_notification = false
      user.save

      post :change_assignements_notification,
           params: { status: true },
           format: :json
      expect(user.reload.assignments_notification).to eq(true)
    end

    it 'changes notification from true => false' do
      user = User.first
      user.assignments_notification = true
      user.save

      post :change_assignements_notification,
           params: { status: false },
           format: :json
      expect(user.reload.assignments_notification).to eq(false)
    end
  end
end
