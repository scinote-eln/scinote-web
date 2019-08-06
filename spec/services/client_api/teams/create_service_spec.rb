# frozen_string_literal: true

require 'rails_helper'

include ClientApi::Teams

describe ClientApi::Teams::CreateService do
  let(:user) { create :user, email: 'user@asdf.com' }
  let(:team) do
    build :team, name: 'My Team', description: 'My Description'
  end

  it 'should raise a StandardError if current_user is not assigned' do
    expect { CreateService.new }.to raise_error(StandardError)
  end

  it 'should create a new team' do
    service = CreateService.new(
      current_user: user,
      params: { name: team.name, description: team.description }
    )
    result = service.execute
    expect(result[:status]).to eq :success

    team_n = Team.order(created_at: :desc).first
    expect(team_n.name).to eq team.name
    expect(team_n.description).to eq team.description
    expect(team_n.created_by).to eq user
    expect(team_n.users.count).to eq 1
    expect(team_n.users.take).to eq user
  end

  it 'should return error response if params = {}' do
    service = CreateService.new(current_user: user, params: {})
    result = service.execute
    expect(result[:status]).to eq :error
  end

  it 'should return error response if params are missing :name attribute' do
    service = CreateService.new(
      current_user: user,
      params: { description: team.description }
    )
    result = service.execute
    expect(result[:status]).to eq :error
  end

  it 'should return error response if name too short' do
    team.name = ('a' * (Constants::NAME_MIN_LENGTH - 1)).to_s
    service = CreateService.new(
      current_user: user,
      params: { name: team.name, description: team.description }
    )
    result = service.execute
    expect(result[:status]).to eq :error
  end

  it 'should return error response if name too long' do
    team.name = ('a' * (Constants::NAME_MAX_LENGTH + 1)).to_s
    service = CreateService.new(
      current_user: user,
      params: { name: team.name, description: team.description }
    )
    result = service.execute
    expect(result[:status]).to eq :error
  end

  it 'should return error response if description too long' do
    team.description = ('a' * (Constants::TEXT_MAX_LENGTH + 1)).to_s
    service = CreateService.new(
      current_user: user,
      params: { name: team.name, description: team.description }
    )
    result = service.execute
    expect(result[:status]).to eq :error
  end
end
