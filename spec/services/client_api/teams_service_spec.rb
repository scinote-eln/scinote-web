# frozen_string_literal: true

require 'rails_helper'

describe ClientApi::TeamsService do
  let(:team_one) { create :team }
  let(:user_one) { create :user }

  it 'should raise an ClientApi::CustomTeamError if user is not assigned' do
    expect do
      ClientApi::TeamsService.new(team_id: team_one.id)
    end.to raise_error(ClientApi::CustomTeamError)
  end

  it 'should raise an ClientApi::CustomTeamError if team is not assigned' do
    expect do
      ClientApi::TeamsService.new(current_user: user_one)
    end.to raise_error(ClientApi::CustomTeamError)
  end

  it 'should raise an ClientApi::CustomTeamError if team is not user team' do
    expect do
      ClientApi::TeamsService.new(current_user: user_one, team_id: team_one.id)
    end.to raise_error(ClientApi::CustomTeamError)
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

    it 'should return an array of valid teams' do
      create :user_team, user: user_one, team: team_one
      expect(team_service.teams_data).to(
        match_response_schema('datatables_teams')
      )
    end
  end

  describe '#update_team!' do
    let(:team_two) { create :team, name: 'Banana', created_by: user_one }

    it 'should raise an error if input invalid' do
      create :user_team, user: user_one, team: team_one
      team_service = ClientApi::TeamsService.new(
        current_user: user_one,
        team_id: team_one.id,
        params: {
          description: "super long: #{'a' * Constants::TEXT_MAX_LENGTH}"
        }
      )
      expect do
        team_service.update_team!
      end.to raise_error(ClientApi::CustomTeamError)
    end

    it 'should update the team description if the input is valid' do
      create :user_team, user: user_one, team: team_two
      desc = 'Banana Team description'
      team_service = ClientApi::TeamsService.new(
        current_user: user_one,
        team_id: team_two.id,
        params: {
          description: desc
        }
      )
      team_service.update_team!
      # load values from db
      team_two.reload
      expect(team_two.description).to eq desc
    end
  end

  describe '#single_team_details_data' do
    let(:team_service) do
      ClientApi::TeamsService.new(current_user: user_one, team_id: team_one.id)
    end

    it 'should return a team object' do
      create :user_team, user: user_one, team: team_one
      expect(team_service.single_team_details_data.fetch(:team)).to eq team_one
    end
  end
end
