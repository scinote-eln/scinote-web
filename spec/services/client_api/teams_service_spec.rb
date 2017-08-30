require 'rails_helper'

describe ClientApi::TeamsService do
  let(:team_one) { create :team }
  let(:user_one) { create :user }

  it 'should raise an ClientApi::CustomTeamError if user is not assigned' do
    expect {
      ClientApi::TeamsService.new(team_id: team_one.id)
    }.to raise_error(ClientApi::CustomTeamError)
  end

  it 'should raise an ClientApi::CustomTeamError if team is not assigned' do
    expect {
      ClientApi::TeamsService.new(current_user: user_one)
    }.to raise_error(ClientApi::CustomTeamError)
  end

  it 'should raise an ClientApi::CustomTeamError if team is not user team' do
    expect {
      ClientApi::TeamsService.new(current_user: user_one, team_id: team_one.id)
    }.to raise_error(ClientApi::CustomTeamError)
  end

  describe '#change_current_team!' do
    let(:team_two) { create :team, name: 'team two' }
    let(:user_two) do
      create :user, current_team_id: team_one.id, email: 'user_two@test.com'
    end

    it 'should change user current team' do
      create :user_team, user: user_two, team: team_two
      teams_service = ClientApi::TeamsService.new(current_user: user_two,
                                                  team_id: team_two.id)
      teams_service.change_current_team!
      expect(user_two.current_team_id).to eq team_two.id
    end
  end

  describe '#team_page_details_data' do
    let(:team_service) do
      ClientApi::TeamsService.new(current_user: user_one, team_id: team_one.id)
    end

    it 'should return team page data' do
      user_team = create :user_team, user: user_one, team: team_one
      data = team_service.team_page_details_data
      expect(data.fetch(:team).name).to eq team_one.name
      expect(data.fetch(:team_users).first).to eq user_team
    end
  end

  describe '#teams_data' do
    let(:team_service) do
      ClientApi::TeamsService.new(current_user: user_one, team_id: team_one.id)
    end

    it 'should return user teams' do
      create :user_team, user: user_one, team: team_one
      data = team_service.teams_data.fetch(:teams)
      expect(data.first.fetch('name')).to eq team_one.name
    end
  end
end
