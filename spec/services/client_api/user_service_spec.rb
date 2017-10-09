require 'rails_helper'

describe ClientApi::UserService do
  let(:user) do
    create :user,
           full_name: 'User One',
           initials: 'UO',
           email: 'user@happy.com',
           password: 'asdf1234',
           password_confirmation: 'asdf1234'
  end

  describe '#update_user!' do
    it 'should update user email if the password is correct' do
      email = 'new_user@happy.com'
      params = { email: email, current_password: 'asdf1234' }
      user_service = ClientApi::UserService.new(current_user: user,
                                                params: params)
      user_service.update_user!
      expect(user.email).to eq(email)
    end

    it 'should raise CustomUserError error if the password is not correct' do
      email = 'new_user@happy.com'
      params = { email: email, current_password: 'banana' }
      user_service = ClientApi::UserService.new(current_user: user,
                                                params: params)
      expect {
        user_service.update_user!
      }.to raise_error(ClientApi::CustomUserError)
    end

    it 'should update initials and full name without password confirmation' do
      full_name = 'Happy User'
      initials = 'HU'
      user_service = ClientApi::UserService.new(
        current_user: user,
        params: { full_name: full_name, initials: initials }
      )
      user_service.update_user!
      expect(user.full_name).to eq(full_name)
      expect(user.initials).to eq(initials)
    end

    it 'should raise an error if current password not present' do
      user_service = ClientApi::UserService.new(
        current_user: user,
        params: { password: 'hello1234', password_confirmation: 'hello1234' }
      )
      expect {
        user_service.update_user!
      }.to raise_error(ClientApi::CustomUserError)
    end

    it 'should raise an error if password_confirmation don\'t match' do
      user_service = ClientApi::UserService.new(
        current_user: user,
        params: { password: 'hello1234',
                  password_confirmation: 'hello1234567890',
                  current_password: 'asdf1234' }
      )

      expect {
        user_service.update_user!
      }.to raise_error(ClientApi::CustomUserError, 'Passwords don\'t match')
    end

    it 'should update the password' do
      new_password = 'hello1234'
      user_service = ClientApi::UserService.new(
        current_user: user,
        params: { password: new_password,
                  password_confirmation: new_password,
                  current_password: 'asdf1234' }
      )
      user_service.update_user!
      expect(user.valid_password?(new_password)).to be(true)
    end
  end
end
