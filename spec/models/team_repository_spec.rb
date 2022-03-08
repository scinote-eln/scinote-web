# frozen_string_literal: true

require 'rails_helper'

describe TeamRepository, type: :model do
  let(:team_repository) { build :team_repository, :read }

  it 'is valid' do
    team_repository.team = create :team
    expect(team_repository).to be_valid
  end

  describe 'Validations' do
    describe '#permission_level' do
      it { is_expected.to validate_presence_of(:permission_level) }
    end
    describe '#repository' do
      it { expect(team_repository).to validate_uniqueness_of(:repository).scoped_to(:team_id) }
    end
    describe '#team' do
      it { expect(team_repository).to validate_uniqueness_of(:repository).scoped_to(:team_id) }

      it 'invalid when repo team is same as sharring team' do
        repo = create :repository
        invalid_team_repository = build :team_repository, :read, repository: repo, team: repo.team

        expect(invalid_team_repository).to be_invalid
      end
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to belong_to(:repository) }
  end
end
