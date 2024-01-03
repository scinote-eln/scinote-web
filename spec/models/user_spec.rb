# frozen_string_literal: true

require 'rails_helper'

describe User, type: :model do
  let(:user) { build :user }

  it 'is valid' do
    expect(user).to be_valid
  end
  it 'should be of class User' do
    expect(subject.class).to eq User
  end

  describe 'Database table' do
    it { should have_db_column :id }
    it { should have_db_column :full_name }
    it { should have_db_column :initials }
    it { should have_db_column :email }
    it { should have_db_column :encrypted_password }
    it { should have_db_column :reset_password_token }
    it { should have_db_column :reset_password_sent_at }
    it { should have_db_column :sign_in_count }
    it { should have_db_column :current_sign_in_at }
    it { should have_db_column :last_sign_in_at }
    it { should have_db_column :current_sign_in_ip }
    it { should have_db_column :last_sign_in_ip }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
    it { should have_db_column :confirmation_token }
    it { should have_db_column :confirmed_at }
    it { should have_db_column :confirmation_sent_at }
    it { should have_db_column :unconfirmed_email }
    it { should have_db_column :invitation_token }
    it { should have_db_column :invitation_created_at }
    it { should have_db_column :invitation_sent_at }
    it { should have_db_column :invitation_accepted_at }
    it { should have_db_column :invitation_limit }
    it { should have_db_column :invited_by_id }
    it { should have_db_column :invited_by_type }
    it { should have_db_column :invitations_count }
    it { should have_db_column :settings }
    it { should have_db_column :variables }
    it { should have_db_column :current_team_id }
    it { should have_db_column :authentication_token }
  end

  describe 'Relations' do
    it { should have_many :teams }
    it { should have_many :user_projects }
    it { should have_many :projects }
    it { should have_many :user_my_modules }
    it { should have_many :comments }
    it { should have_many :activities }
    it { should have_many :results }
    it { should have_many :repository_table_states }
    it { should have_many :steps }
    it { should have_many :reports }
    it { should have_many :created_assets }
    it { should have_many :modified_assets }
    it { should have_many :created_checklists }
    it { should have_many :modified_checklists }
    it { should have_many :created_checklist_items }
    it { should have_many :modified_checklist_items }
    it { should have_many :modified_comments }
    it { should have_many :created_my_module_groups }
    it { should have_many :created_my_module_tags }
    it { should have_many :created_my_modules }
    it { should have_many :modified_my_modules }
    it { should have_many :archived_my_modules }
    it { should have_many :restored_my_modules }
    it { should have_many :created_teams }
    it { should have_many :modified_teams }
    it { should have_many :created_projects }
    it { should have_many :modified_projects }
    it { should have_many :archived_projects }
    it { should have_many :restored_projects }
    it { should have_many :modified_reports }
    it { should have_many :archived_results }
    it { should have_many :restored_results }
    it { should have_many :created_tables }
    it { should have_many :modified_tables }
    it { should have_many :created_tags }
    it { should have_many :tokens }
    it { should have_many :modified_tags }
    it { should have_many :assigned_user_my_modules }
    it { should have_many :assigned_user_projects }
    it { should have_many :added_protocols }
    it { should have_many :archived_protocols }
    it { should have_many :restored_protocols }
    it { should have_many :assigned_my_module_repository_rows }
    it { should have_many :notifications }
    it { should have_many :zip_exports }
    it { should have_many(:shareable_links).dependent(:destroy) }

    it 'have many repositories' do
      table = User.reflect_on_association(:repositories)
      expect(table.macro).to eq(:has_many)
    end

    it 'have many modified results' do
      table = User.reflect_on_association(:modified_results)
      expect(table.macro).to eq(:has_many)
    end

    it 'have many modified steps' do
      table = User.reflect_on_association(:modified_steps)
      expect(table.macro).to eq(:has_many)
    end
  end

  describe 'Validations' do
    it { should validate_presence_of :full_name }
    it { should validate_presence_of :initials  }
    it { should validate_presence_of :email }

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

  describe 'user settings' do
    it { is_expected.to respond_to(:time_zone) }
  end

  describe 'user variables' do
    it { is_expected.to respond_to(:export_vars) }
  end

  describe '#last_activities' do
    let!(:user) { create :user }
    let!(:project) { create :project }
    let!(:user_projects) do
      create :user_project, :viewer, project: project, user: user
    end
    let!(:activity_one) { create :activity, owner: user, project: project }
    let!(:activity_two) { create :activity, owner: user, project: project }

    it 'is expected to return an array of user\'s activities' do
      activities = user.last_activities
      expect(activities.count).to eq 2
      expect(activities).to include activity_one
      expect(activities).to include activity_two
    end
  end

  describe '#increase_daily_exports_counter!' do
    let(:user) { create :user }
    context 'when last_export_timestamp is set' do
      it 'increases counter by 1' do
        expect { user.increase_daily_exports_counter! }
          .to change {
            user.reload.export_vars['num_of_export_all_last_24_hours']
          }.from(0).to(1)
      end

      it 'sets last_export_timestamp on today\'s timestamp' do
        user.export_vars['last_export_timestamp'] = Date.yesterday.to_time.to_i
        user.save

        expect { user.increase_daily_exports_counter! }
          .to change {
            user.reload.export_vars['last_export_timestamp']
          }.to(Time.now.utc.beginning_of_day.to_i..Time.now.utc.end_of_day.to_i)
      end

      it 'sets new counter for today' do
        user.export_vars = {
          'num_of_export_all_last_24_hours': 3,
          'last_export_timestamp': Date.yesterday.to_time.to_i
        }
        user.save

        expect { user.increase_daily_exports_counter! }
          .to change {
            user.reload.export_vars['num_of_export_all_last_24_hours']
          }.from(3).to(1)
      end
    end

    context 'when last_export_timestamp not exists (existing users)' do
      it 'sets last_export_timestamp on today\'s timestamp' do
        user.export_vars.delete('last_export_timestamp')
        user.save

        expect { user.increase_daily_exports_counter! }
          .to change {
            user.reload.export_vars['last_export_timestamp']
          }.from(nil).to(Time.now.utc.beginning_of_day.to_i..Time.now.utc.end_of_day.to_i)
      end

      it 'starts count reports with 1' do
        user.export_vars.delete('last_export_timestamp')
        user.export_vars['num_of_export_all_last_24_hours'] = 2
        user.save

        expect { user.increase_daily_exports_counter! }
          .to change {
            user.reload.export_vars['num_of_export_all_last_24_hours']
          }.from(2).to(1)
      end
    end

    context 'when num_of_export not exists' do
      it 'starts count reports with 1' do
        user.export_vars.delete('num_of_export_all_last_24_hours')
        user.save

        expect { user.increase_daily_exports_counter! }
          .to change {
            user.reload.export_vars['num_of_export_all_last_24_hours']
          }.from(nil).to(1)
      end
    end
  end

  describe '#has_available_exports?' do
    let(:user) { create :user }

    context 'when user have export_vars' do
      it 'returns true when user has avaiable export' do
        expect(user.has_available_exports?).to be_truthy
      end

      it 'returns false when user has no avaiable export' do
        user.export_vars['num_of_export_all_last_24_hours'] = 3

        expect(user.has_available_exports?).to be_falsey
      end
    end

    context 'when user do not have export_vars' do
      it 'returns false when user has no avaiable export' do
        user.export_vars = {}

        expect(user.has_available_exports?).to be_truthy
      end
    end
  end

  describe '#exports_left' do
    let(:user) { create :user }
    context 'when user do have export_vars' do
      it 'returns 3 when user has all exports avaible' do
        expect(user.exports_left).to be == 3
      end

      it 'returns 0 when user has no avaiable export' do
        user.export_vars['num_of_export_all_last_24_hours'] = 3

        expect(user.exports_left).to be == 0
      end

      it 'returns 3 when user has invalid number from the past' do
        user.export_vars['num_of_export_all_last_24_hours'] = -4
        user.export_vars['last_export_timestamp'] = Date.yesterday.to_time.utc.to_i

        expect(user.exports_left).to be == 3
      end
    end

    context 'when user do not have export_vars' do
      it 'returns false when user has no avaiable export' do
        user.export_vars = {}

        expect(user.exports_left).to be == 3
      end
    end
  end

  describe 'Email downcase' do
    it 'downcases email before validating and saving user' do
      user = User.new(email: 'Test@Email.com')
      user.save
      expect(user.email).to eq('test@email.com')
    end
  end

  describe 'valid_otp?' do
    let(:user) { create :user }
    before do
      user.assign_2fa_token!
      allow_any_instance_of(ROTP::TOTP).to receive(:verify).and_return(nil)
    end

    context 'when user has set otp_secret' do
      it 'returns nil' do
        expect(user.valid_otp?('someString')).to be_nil
      end
    end

    context 'when user does not have otp_secret' do
      it 'raises an error' do
        user.update_column(:otp_secret, nil)

        expect { user.valid_otp?('someString') }.to raise_error(StandardError, 'Missing otp_secret')
      end
    end
  end
end
