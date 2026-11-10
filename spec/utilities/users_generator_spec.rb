# frozen_string_literal: true

require 'rails_helper'

describe UsersGenerator do
  let(:generator) { Object.new.extend(described_class) }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  # Creating a team runs the template project setup, which needs the predefined viewer role
  let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }

  describe '#get_user_initials' do
    it 'uses the first letter of each name part' do
      expect(generator.get_user_initials('Jane Doe')).to eq 'JD'
    end

    it 'keeps at most four initials' do
      expect(generator.get_user_initials('jane van der berg extra')).to eq 'JVDB'
    end

    it 'capitalises lowercase names' do
      expect(generator.get_user_initials('ana perez')).to eq 'AP'
    end
  end

  describe '#generate_user_password' do
    it 'returns an alphanumeric password of the maximum Devise length' do
      password = generator.generate_user_password

      expect(password.length).to eq Devise.password_length.max
      expect(password).to match(/\A[a-zA-Z0-9]+\z/)
    end
  end

  describe '#validate_user' do
    it 'returns no errors for a valid user' do
      expect(generator.validate_user('Jane Doe', 'jane.doe@example.com', 'Secret-Pass-123')).to be_empty
    end

    it 'reports the invalid email' do
      errors = generator.validate_user('Jane Doe', 'not-an-email', 'Secret-Pass-123')

      expect(errors).to include(:email)
    end

    it 'reports a blank password' do
      errors = generator.validate_user('Jane Doe', 'jane.doe@example.com', '')

      expect(errors).to include(:password)
    end

    it 'does not persist the user' do
      expect { generator.validate_user('Jane Doe', 'jane.doe@example.com', 'Secret-Pass-123') }
        .not_to change(User, :count)
    end
  end

  describe '#create_user' do
    let(:team_owner) { create :user }
    let(:other_team) { create :team, created_by: team_owner }

    it 'creates a confirmed user with initials and a private team' do
      user = generator.create_user('Jane Doe', 'jane.doe@example.com', 'Secret-Pass-123', true, 'Jane lab', [])

      expect(user).to be_persisted
      expect(user.initials).to eq 'JD'
      expect(user.confirmed_at).to be_present
      expect(user.teams.map(&:name)).to contain_exactly('Jane lab')
      expect(user.current_team_id).to eq user.teams.first.id
    end

    it 'leaves the user unconfirmed when requested' do
      user = generator.create_user('Max Roe', 'max.roe@example.com', 'Secret-Pass-123', false, nil, [])

      expect(user.confirmed_at).to be_nil
    end

    it 'does not create a private team when no name is given' do
      user = generator.create_user('Max Roe', 'max.roe@example.com', 'Secret-Pass-123', true, nil, [])

      expect(user.teams).to be_empty
      expect(user.current_team_id).to be_nil
    end

    it 'assigns the user as owner of the given teams and makes the first one current' do
      user = generator.create_user('Max Roe', 'max.roe@example.com', 'Secret-Pass-123', true, nil, [other_team.id])

      assignment = UserAssignment.find_by(user: user, assignable: other_team)
      expect(assignment.user_role).to eq owner_role
      expect(user.current_team_id).to eq other_team.id
    end
  end

  describe '#print_user' do
    let(:user) { create :user, full_name: 'Jane Doe', initials: 'JD', email: 'jane.doe@example.com' }
    let(:team) { create :team, created_by: user, name: 'Jane team' }

    before { create_user_assignment(team, owner_role, user) }

    it 'prints the account details and team membership' do
      expect { generator.print_user(user.reload, 'Secret-Pass-123') }.to output(
        "USER ##{user.id}\n" \
        "  Full name: Jane Doe\n" \
        "  Initials: JD\n" \
        "  Email: jane.doe@example.com\n" \
        "  Password: Secret-Pass-123\n" \
        "  Confirmed at: #{user.confirmed_at}\n" \
        "  Member of teams: Jane team\n"
      ).to_stdout
    end
  end
end
