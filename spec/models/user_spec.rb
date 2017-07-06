require 'rails_helper'

describe User, type: :model do
  it 'should be of class User' do
    expect(subject.class).to eq User
  end

  describe 'Database table' do
    it { is_expected.to have_db_column :id }
    it { is_expected.to have_db_column :full_name }
    it { is_expected.to have_db_column :initials }
    it { is_expected.to have_db_column :email }
    it { is_expected.to have_db_column :encrypted_password }
    it { is_expected.to have_db_column :reset_password_token }
    it { is_expected.to have_db_column :reset_password_sent_at }
    it { is_expected.to have_db_column :sign_in_count }
    it { is_expected.to have_db_column :current_sign_in_at }
    it { is_expected.to have_db_column :last_sign_in_at }
    it { is_expected.to have_db_column :current_sign_in_ip }
    it { is_expected.to have_db_column :last_sign_in_ip }
    it { is_expected.to have_db_column :created_at }
    it { is_expected.to have_db_column :updated_at }
    it { is_expected.to have_db_column :avatar_file_name }
    it { is_expected.to have_db_column :avatar_content_type }
    it { is_expected.to have_db_column :avatar_file_size }
    it { is_expected.to have_db_column :avatar_updated_at }
    it { is_expected.to have_db_column :confirmation_token }
    it { is_expected.to have_db_column :confirmed_at }
    it { is_expected.to have_db_column :confirmation_sent_at }
    it { is_expected.to have_db_column :unconfirmed_email }
    it { is_expected.to have_db_column :time_zone }
    it { is_expected.to have_db_column :invitation_token }
    it { is_expected.to have_db_column :invitation_created_at }
    it { is_expected.to have_db_column :invitation_sent_at }
    it { is_expected.to have_db_column :invitation_accepted_at }
    it { is_expected.to have_db_column :invitation_limit }
    it { is_expected.to have_db_column :invited_by_id }
    it { is_expected.to have_db_column :invited_by_type }
    it { is_expected.to have_db_column :invitations_count }
    it { is_expected.to have_db_column :tutorial_status }
    it { is_expected.to have_db_column :assignments_notification }
    it { is_expected.to have_db_column :recent_notification }
    it { is_expected.to have_db_column :assignments_notification_email }
    it { is_expected.to have_db_column :recent_notification_email }
    it { is_expected.to have_db_column :current_team_id }
    it { is_expected.to have_db_column :system_message_notification_email }
    it { is_expected.to have_db_column :authentication_token }
  end

  describe 'Should be a valid object' do
    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:initials) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:time_zone) }

    it do
      should validate_length_of(:full_name).is_at_most(
        Constants::NAME_MAX_LENGTH
      )
    end

    it do
      should validate_length_of(:initials).is_at_most(
        Constants::USER_INITIALS_MAX_LENGTH
      )
    end

    it do
      should validate_length_of(:email).is_at_most(
        Constants::EMAIL_MAX_LENGTH
      )
    end
  end

  describe 'Should return a user name' do
    let(:user) { build :user, full_name: 'Tinker' }

    it 'should return a user full name' do
      expect(user.name).to eq 'Tinker'
    end

    it 'should to be able to change full name' do
      user.name = 'Axe'
      expect(user.name).to_not eq 'Tinker'
      expect(user.name).to eq 'Axe'
    end
  end
end
