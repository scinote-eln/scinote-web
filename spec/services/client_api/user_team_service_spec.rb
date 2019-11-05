# frozen_string_literal: true

require 'rails_helper'

describe ClientApi::UserTeamService do
  let(:team_one) { create :team }
  let(:user_one) { create :user, email: Faker::Internet.email }
  let(:user_two) { create :user, email: Faker::Internet.email }
  let(:user_team) { create :user_team, :admin, user: user_one, team: team_one }

  it 'should raise ClientApi::CustomUserTeamError if user is not assigned' do
    expect do
      ClientApi::UserTeamService.new(
        team_id: team_one.id,
        user_team_id: user_team.id
      )
    end.to raise_error(ClientApi::CustomUserTeamError)
  end

  it 'should raise ClientApi::CustomUserTeamError if team is not assigned' do
    expect do
      ClientApi::UserTeamService.new(user: user_one, user_team_id: user_team.id)
    end.to raise_error(ClientApi::CustomUserTeamError)
  end

  it 'should raise ClientApi::CustomUserTeamError if ' \
     'user_team is not assigned' do
    expect do
      ClientApi::UserTeamService.new(user: user_one, team_id: team_one.id)
    end.to raise_error(ClientApi::CustomUserTeamError)
  end

  describe '#destroy_user_team_and_assign_new_team_owner!' do
    it 'should raise ClientApi::CustomUserTeamError if user ' \
       'can\'t leave the team' do
      ut_service = ClientApi::UserTeamService.new(
        team_id: team_one.id,
        user_team_id: user_team.id,
        user: user_one
      )
      expect do
        ut_service.destroy_user_team_and_assign_new_team_owner!
      end.to raise_error(ClientApi::CustomUserTeamError)
    end

    it 'should destroy the user_team relation' do
      create :user_team, :admin, team: team_one, user: user_one
      new_user_team = create :user_team, team: team_one, user: user_two
      ut_service = ClientApi::UserTeamService.new(
        team_id: team_one.id,
        user_team_id: new_user_team.id,
        user: user_one
      )
      ut_service.destroy_user_team_and_assign_new_team_owner!
      expect(team_one.users).to_not include user_two
    end

    it 'should assign a new owner to the team' do
      user_team_one = create :user_team, team: team_one, user: user_one
      create :user_team, :admin, team: team_one, user: user_two
      ut_service = ClientApi::UserTeamService.new(
        team_id: team_one.id,
        user_team_id: user_team_one.id,
        user: user_one
      )
      ut_service.destroy_user_team_and_assign_new_team_owner!
      expect(team_one.users).to include user_two
    end
  end

  describe '#update_role!' do
    it 'should raise ClientApi::CustomUserTeamError if no role is set' do
      ut_service = ClientApi::UserTeamService.new(
        user: user_one,
        team_id: team_one.id,
        user_team_id: user_team.id
      )
      expect do
        ut_service.update_role!
      end.to raise_error(ClientApi::CustomUserTeamError)
    end

    it 'should update user role' do
      create :user_team, team: team_one, user: user_two
      user_team = create :user_team, team: team_one, user: user_one
      ut_service = ClientApi::UserTeamService.new(
        user: user_one,
        team_id: team_one.id,
        user_team_id: user_team.id,
        role: 1
      )
      ut_service.update_role!
      user_team.reload
      expect(user_team.role).to eq 'normal_user'
    end

    it 'should raise ClientApi::CustomUserTeamError if is the last ' \
       'admin on the team' do
      user_team = create :user_team, :admin, team: team_one, user: user_one
      ut_service = ClientApi::UserTeamService.new(
        user: user_one,
        team_id: team_one.id,
        user_team_id: user_team.id,
        role: 1
      )
      expect do
        ut_service.update_role!
      end.to raise_error(ClientApi::CustomUserTeamError)
    end
  end

  describe '#team_users_data' do
    it 'should return a hash of team members' do
      user_team = create :user_team, team: team_one, user: user_one
      ut_service = ClientApi::UserTeamService.new(
        user: user_one,
        team_id: team_one.id,
        user_team_id: user_team.id,
        role: 1
      )
      expect(ut_service.team_users_data.fetch(:team_users)).to include user_team
    end
  end

  describe '#teams_data' do
    it 'should return a list of teams where user is a member' do
      user_team = create :user_team, team: team_one, user: user_one
      ut_service = ClientApi::UserTeamService.new(
        user: user_one,
        team_id: team_one.id,
        user_team_id: user_team.id,
        role: 1
      )
      team_id = ut_service.teams_data[:teams].first.id
      expect(team_id).to eq team_one.id
    end
  end
end
