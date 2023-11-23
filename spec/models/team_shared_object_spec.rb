# frozen_string_literal: true

require 'rails_helper'

describe TeamSharedObject, type: :model do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:another_team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:team_shared_object) { create :team_shared_object, :read, team: another_team, shared_object: repository }

  before do
    allow_any_instance_of(TeamSharedObject).to receive(:team_cannot_be_the_same)
  end

  it 'is valid' do
    expect(team_shared_object).to be_valid
  end

  it 'should be of class TeamSharedObject' do
    expect(subject.class).to eq TeamSharedObject
  end

  describe 'Relations' do
    it { should belong_to(:team) }
    it { should belong_to(:shared_object) }
    it { should belong_to(:shared_repository).optional }
  end
end
