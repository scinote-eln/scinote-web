# frozen_string_literal: true

require 'rails_helper'

describe TeamsHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:other_team) { create :team, created_by: user }

  before do
    without_partial_double_verification do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:current_team).and_return(team)
    end
  end

  def stub_set_current_team
    calls = 0
    without_partial_double_verification { allow(helper).to receive(:set_current_team) { calls += 1 } }
    define_singleton_method(:switched_calls) { calls }
  end

  describe '#truncate_team_name' do
    it 'returns a short name unchanged' do
      expect(helper.truncate_team_name('Short')).to eq 'Short'
    end

    it 'returns a tooltip block with the truncated and the full name for a long name' do
      name = 'A very long workspace name that overflows'

      result = helper.truncate_team_name(name)

      expect(result).to include("class=\"modal-tooltip\"")
      expect(result).to include(name.truncate(Constants::NAME_TRUNCATION_LENGTH))
      expect(result).to include("<span class=\"modal-tooltiptext\">#{name}</span>")
    end

    it 'respects a custom length' do
      expect(helper.truncate_team_name('abcdefgh', 5)).to include('ab...')
    end
  end

  describe '#current_team_switch' do
    it 'switches the current team of a member' do
      other_team
      stub_set_current_team

      helper.current_team_switch(other_team)

      expect(user.reload.current_team_id).to eq other_team.id
      expect(switched_calls).to eq 1
    end

    it 'does nothing for the current team' do
      user.update!(current_team_id: team.id)
      stub_set_current_team

      helper.current_team_switch(team)

      expect(switched_calls).to eq 0
    end

    it 'does nothing when the user is not a member of the team' do
      foreign = create :team, created_by: create(:user)
      stub_set_current_team

      helper.current_team_switch(foreign)

      expect(user.reload.current_team_id).not_to eq foreign.id
      expect(switched_calls).to eq 0
    end
  end

  describe '#switch_team_with_param' do
    before do
      other_team
      stub_set_current_team
    end

    it 'switches to the team given as team param' do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(team: other_team.id))

      helper.switch_team_with_param

      expect(user.reload.current_team_id).to eq other_team.id
    end

    it 'switches to the team given as team_id param' do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(team_id: other_team.id))

      helper.switch_team_with_param

      expect(user.reload.current_team_id).to eq other_team.id
    end

    it 'does nothing without a team param' do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new({}))

      helper.switch_team_with_param

      expect(switched_calls).to eq 0
    end
  end
end
