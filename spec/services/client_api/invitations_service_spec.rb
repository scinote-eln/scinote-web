# frozen_string_literal: true

require 'rails_helper'

describe ClientApi::InvitationsService do
  let(:team_one) { create :team }
  let(:user_one) { create :user, email: Faker::Internet.email }
  let(:emails_one) { Array.new(3) { Faker::Internet.email } }

  it 'raises an ClientApi::CustomInvitationsError if ' \
     'role is not assigned' do
    expect do
      ClientApi::InvitationsService.new(user: user_one,
                                        team: team_one,
                                        emails: emails_one)
    end.to raise_error(ClientApi::CustomInvitationsError)
  end

  it 'raises an ClientApi::CustomInvitationsError if ' \
     'emails are not assigned' do
    expect do
      ClientApi::InvitationsService.new(user: user_one,
                                        team: team_one,
                                        role: 'normal_user')
    end.to raise_error(ClientApi::CustomInvitationsError)
  end

  it 'raises an ClientApi::CustomInvitationsError if ' \
     'emails are not present' do
    expect do
      ClientApi::InvitationsService.new(user: user_one,
                                        team: team_one,
                                        role: 'normal_user',
                                        emails: [])
    end.to raise_error(ClientApi::CustomInvitationsError)
  end

  it 'raises an ClientApi::CustomInvitationsError if ' \
     'role is not included in UserTeam.roles' do
    expect do
      ClientApi::InvitationsService.new(user: user_one,
                                        team: team_one,
                                        role: 'abnormal_user',
                                        emails: emails_one)
    end.to raise_error(ClientApi::CustomInvitationsError)
  end

  describe '#invitation' do
    it 'returns too many emails response if invite users limit is exceeded' do
      emails_exceeded = Array.new(Constants::INVITE_USERS_LIMIT + 1) do
        Faker::Internet.email
      end
      invitation_service = ClientApi::InvitationsService.new(
        user: user_one,
        team: team_one,
        role: 'normal_user',
        emails: emails_exceeded
      )
      result = invitation_service.invitation
      expect(result.last[:status]).to eq :too_many_emails
      expect(result.count).to eq Constants::INVITE_USERS_LIMIT + 1
    end

    context 'when user is new' do
      it 'returns invalid response if invited user is not valid' do
        invitation_service = ClientApi::InvitationsService.new(
          user: user_one,
          role: 'normal_user',
          emails: ['banana.man']
        )
        result_status = invitation_service.invitation.last[:status]
        expect(result_status).to eq :user_invalid
      end

      it 'invites new user' do
        invitation_service = ClientApi::InvitationsService.new(
          user: user_one,
          role: 'normal_user',
          emails: ['new@banana.net']
        )
        result = invitation_service.invitation
        expect(result.last[:status]).to eq :user_created
        # test functions result
        expect(result.last[:user].email).to eq 'new@banana.net'
        expect(result.last[:user].invited_by).to eq user_one
        # test in database
        expect(User.last.email).to eq 'new@banana.net'
        expect(User.last.invited_by).to eq user_one
      end

      it 'creates user-team relation and notification if team present' do
        invitation_service = ClientApi::InvitationsService.new(
          user: user_one,
          team: team_one,
          role: 'normal_user',
          emails: ['new@banana.net']
        )
        result_status = invitation_service.invitation.last[:status]
        expect(result_status).to eq :user_created_invited_to_team
        expect(User.find_by_email('new@banana.net').teams).to include team_one
        expect(Notification.last.users.last[:email]).to eq 'new@banana.net'
      end
    end

    context 'when user already exists' do
      let(:user_two) { create :user, email: Faker::Internet.email }
      let(:service_one) do
        ClientApi::InvitationsService.new(user: user_one,
                                          team: team_one,
                                          role: 'normal_user',
                                          emails: [user_two.email])
      end

      it 'returns information, that user already exists' do
        invitation_service = ClientApi::InvitationsService.new(
          user: user_one,
          role: 'normal_user',
          emails: [user_two.email]
        )
        result_status = invitation_service.invitation.last[:status]
        expect(result_status).to eq :user_exists_unconfirmed
      end

      it 'returns user exists in team response if team present ' \
         'and user already part of the team' do
        create :user_team, team: team_one, user: user_two
        result_status = service_one.invitation.last[:status]
        expect(result_status).to eq :user_exists_and_in_team_unconfirmed
      end

      it 'creates user-team relation and notification if team present ' \
         'and user not part of the team' do
        result_status = service_one.invitation.last[:status]
        expect(result_status).to eq :user_exists_invited_to_team_unconfirmed
        expect(User.find_by_email(user_two.email).teams).to include team_one
        expect(Notification.last.users.last[:email]).to eq user_two.email
      end
    end
  end
end
