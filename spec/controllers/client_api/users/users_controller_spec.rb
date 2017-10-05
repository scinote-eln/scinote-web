require 'rails_helper'

describe ClientApi::Users::UsersController, type: :controller do
  login_user

  before do
    # user password is set in user factory defaults to 'asdf1243'
    @user = User.first
  end

  describe 'GET current_user_info' do
    it 'responds successfully' do
      get :current_user_info, format: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST update' do
    let(:new_password) { 'secretPassword' }

    it 'responds successfully if all password params are set' do
      post :update,
           params: { user: { password: new_password,
                             password_confirmation: new_password,
                             current_password: 'asdf1243' } },
           format: :json

      expect(response).to have_http_status(:ok)
    end

    it 'responds unsuccessfully if no current_password is provided' do
      post :update,
           params: { user: { password: new_password,
                             password_confirmation: new_password } },
           format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds unsuccessfully if no password_confirmation is provided' do
      post :update,
           params: { user: { password: new_password,
                             current_password: 'asdf1243' } },
           format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds successfully if time_zone is updated' do
      post :update, params: { user: { time_zone: 'Pacific/Fiji' } },
                             format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes timezone' do
      user = User.first
      expect(user.time_zone).to eq('UTC')
      post :update, params: { user: { time_zone: 'Pacific/Fiji' } },
                             format: :json
      expect(user.reload.time_zone).to eq('Pacific/Fiji')
    end

    it 'responds successfully if initials are provided' do
      post :update, params: { user: { initials: 'TD' } }, format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'updates user initials' do
      user = User.first
      expect(user.initials).not_to eq('TD')
      post :update, params: { user: { initials: 'TD' } }, format: :json
      expect(user.reload.initials).to eq('TD')
    end

    it 'responds successfully if system_message_email_notification provided' do
      post :update,
           params: { user: { system_message_email_notificationatus: 'false' } },
           format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes system_message_email_notification from false => true' do
      user = User.first
      user.system_message_email_notification = false
      user.save

      post :update,
           params: { user: { system_message_email_notification: true } },
           format: :json
      expect(user.reload.system_message_email_notification).to eql('true')
    end

    it 'changes system_message_email_notification from true => false' do
      user = User.first
      user.system_message_email_notification = true
      user.save

      post :update,
           params: { user: { system_message_email_notification: false } },
           format: :json
      expect(user.reload.system_message_email_notification).to eql('false')
    end

    it 'responds successfully if recent_email_notification provided' do
      post :update,
           params: { user: { recent_email_notification: false } },
           format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes recent_email_notification from false => true' do
      user = User.first
      user.recent_email_notification = false
      user.save

      post :update,
           params: { user: { recent_email_notification: true } },
           format: :json
      expect(user.reload.recent_email_notification).to eql('true')
    end

    it 'changes notification from true => false' do
      user = User.first
      user.recent_email_notification = true
      user.save

      post :update,
           params: { user: { recent_email_notification: false } },
           format: :json
      expect(user.reload.recent_email_notification).to eql('false')
    end

    it 'responds successfully if recent_notification provided' do
      post :update, params: { user: { recent_notification: false } },
                    format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes recent_notification from false => true' do
      user = User.first
      user.recent_notification = false
      user.save

      post :update, params: { user: { recent_notification: true } },
                  format: :json
      expect(user.reload.recent_notification).to eql('true')
    end

    it 'changes recent_notification from true => false' do
      user = User.first
      user.recent_notification = true
      user.save

      post :update, params: { user: { recent_notification: false } },
                    format: :json
      expect(user.reload.recent_notification).to eq('false')
    end

    it 'responds successfully if assignments_email_notification provided' do
      post :update,
           params: { user: { assignments_email_notification: false } },
           format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes assignments_email_notification from false => true' do
      user = User.first
      user.assignments_email_notification = false
      user.save

      post :update,
           params: { user: { assignments_email_notification: true } },
           format: :json
      expect(user.reload.assignments_email_notification).to eq('true')
    end

    it 'changes assignments_email_notification from true => false' do
      user = User.first
      user.assignments_email_notification = true
      user.save

      post :update,
           params: { user: { assignments_email_notification: false } },
           format: :json
      expect(user.reload.assignments_email_notification).to eq('false')
    end

    it 'responds successfully if assignments_notification provided' do
      post :update,
           params: { user: { assignments_notification: false } },
           format: :json
      expect(response).to have_http_status(:ok)
    end

    it 'changes assignments_notification from false => true' do
      user = User.first
      user.assignments_notification = false
      user.save

      post :update,
           params: { user: { assignments_notification: true } },
           format: :json
      expect(user.reload.assignments_notification).to eq('true')
    end

    it 'changes assignments_notification from true => false' do
      user = User.first
      user.assignments_notification = true
      user.save

      post :update,
           params: { user: { assignments_notification: false } },
           format: :json
      expect(user.reload.assignments_notification).to eq('false')
    end
  end
end
