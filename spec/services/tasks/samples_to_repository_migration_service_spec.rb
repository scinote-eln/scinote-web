require 'rails_helper'

describe Tasks::SamplesToRepositoryMigrationService do
  let(:user) { create :user, email: 'happy.user@scinote.net' }
  let(:team) { create :team, created_by: :user }
  let(:user_team) { create :user_team, user: user, team: team }
  let(:sample) { create :sample, name: 'my sample', user: user, team: team }

  describe '#prepare_repository/2' do
    it 'creates and return a new custom repository named "Samples" for team' do
      repository = SamplesToRepositoryMigrationService.prepare_repository(team)
      expect(repository).to be_an_instance_of(Repository)
      expect(repository.team).to eq team
      expect(repository.name).to eq 'Samples'
    end
  end

  describe '#prepare_text_value_custom_columns/2' do

  end

  describe '#prepare_list_value_custom_columns_with_list_items/2' do

  end

  describe '#get_sample_fields/1' do

  end

  describe '#get_assigned_sample_module/1' do

  end
end
