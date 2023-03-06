# frozen_string_literal: true

require 'rails_helper'

describe TeamSharedObject, type: :model do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:another_team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:team_shared_object) { build :team_shared_object, :read, team: another_team, shared_repository: repository }

  it 'is valid' do
    expect(team_shared_object).to be_valid
  end


  describe 'Associations' do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:shared_repository) }
    it { is_expected.to belong_to(:shared_object) }
  end
end
