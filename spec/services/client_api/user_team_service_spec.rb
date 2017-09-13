require 'rails_helper'

describe ClientApi::UserTeamService do
  let(:team_one) { create :team }
  let(:user_one) { create :user, email: Faker::Internet.email }
  let(:user_team) { create :user_team, user: user_one, team: team_one }

  it 'should raise ClientApi::CustomUserTeamError if user is not assigned' do
    expect {
      ClientApi::UserTeamService.new(
        team_id: team_one.id,
        user_team_id: user_team.id
      )
    }.to raise_error(ClientApi::CustomUserTeamError)
  end

  it 'should raise ClientApi::CustomUserTeamError if team is not assigned' do
    expect {
      ClientApi::UserTeamService.new(user: user_one, user_team_id: user_team.id)
    }.to raise_error(ClientApi::CustomUserTeamError)
  end

  it 'should raise ClientApi::CustomUserTeamError if ' \
     'user_team is not assigned' do
    expect {
      ClientApi::UserTeamService.new(user: user_one, team_id: team_one.id)
    }.to raise_error(ClientApi::CustomUserTeamError)
  end

  describe '#destroy_user_team_and_assign_new_team_owner!' do
    let(:user_two) { create :user, email: Faker::Internet.email }

    it 'should raise ClientApi::CustomUserTeamError if user ' \
       'can\'t leave the team' do
      ut_service = ClientApi::UserTeamService.new(
        team_id: team_one.id,
        user_team_id: user_team.id,
        user: user_one
      )
      expect {
        ut_service.destroy_user_team_and_assign_new_team_owner!
      }.to raise_error(ClientApi::CustomUserTeamError)
    end

    it 'should destroy the user_team relation' do
      new_user_team = create :user_team, team: team_one, user: user_two
      ut_service = ClientApi::UserTeamService.new(
        team_id: team_one.id,
        user_team_id: new_user_team.id,
        user: user_two
      )
      ut_service.destroy_user_team_and_assign_new_team_owner!
      expect(new_user_team).to_not exist
    end
  end
end
