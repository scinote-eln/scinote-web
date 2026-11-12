# frozen_string_literal: true

require 'rails_helper'

describe 'protocol_keyword_team:exec' do
  include_context 'rake file loaded once', 'protocol_keyword_team'

  let(:team) { create :team }
  let(:other_team) { create :team }

  def run_task
    expect { rake_task('protocol_keyword_team:exec').invoke }.to output(/Start processing.*Done!/m).to_stdout
  end

  context 'when a protocol keyword belongs to a different team than the protocol' do
    let(:protocol) { create :protocol, team: team }
    let(:wrong_keyword) { create :protocol_keyword, team: other_team, name: 'wrong-team-kw' }

    before { create :protocol_protocol_keyword, protocol: protocol, protocol_keyword: wrong_keyword }

    it 'replaces the keyword with a new one in the protocol team' do
      run_task

      keywords = protocol.reload.protocol_keywords
      expect(keywords.map(&:name)).to eq(['wrong-team-kw'])
      expect(keywords.first.team_id).to eq(team.id)
      expect(keywords.first.id).not_to eq(wrong_keyword.id)
    end

    it 'removes the old link (the orphaned keyword is destroyed by the join model callback)' do
      run_task

      expect(ProtocolProtocolKeyword.where(protocol_keyword_id: wrong_keyword.id)).to be_empty
      expect(other_team.protocol_keywords.reload).to be_empty
    end
  end

  context 'when keywords already belong to the protocol team' do
    let(:protocol) { create :protocol, team: team }
    let!(:keyword) { create :protocol_keyword, team: team, name: 'fine-kw' }

    before { create :protocol_protocol_keyword, protocol: protocol, protocol_keyword: keyword }

    it 'does not change anything' do
      run_task

      expect(protocol.reload.protocol_keywords.pluck(:id)).to eq([keyword.id])
    end
  end

  context 'when a team has duplicate keywords' do
    let(:protocol_a) { create :protocol, team: team }
    let(:protocol_b) { create :protocol, team: team }
    let!(:keyword_a) { create :protocol_keyword, team: team, name: 'dup-kw' }
    let!(:keyword_b) do
      create(:protocol_keyword, team: team, name: 'dup-kw-tmp').tap do |k|
        k.update_column(:name, 'dup-kw') # bypass the uniqueness validation
      end
    end
    let!(:unique_keyword) { create :protocol_keyword, team: team, name: 'unique-kw' }

    before do
      create :protocol_protocol_keyword, protocol: protocol_a, protocol_keyword: keyword_a
      create :protocol_protocol_keyword, protocol: protocol_b, protocol_keyword: keyword_b
      create :protocol_protocol_keyword, protocol: protocol_b, protocol_keyword: unique_keyword
    end

    it 'merges duplicates into one keyword linked to all protocols' do
      run_task

      merged = team.protocol_keywords.where(name: 'dup-kw')
      expect(merged.count).to eq(1)
      expect(merged.first.protocols.pluck(:id)).to match_array([protocol_a.id, protocol_b.id])
      expect(ProtocolKeyword.where(id: [keyword_a.id, keyword_b.id])).to be_empty
    end

    it 'does not touch unique keywords' do
      run_task

      expect(ProtocolKeyword.find(unique_keyword.id).protocols.pluck(:id)).to eq([protocol_b.id])
    end
  end

  context 'when there is nothing to fix' do
    it 'only prints the progress messages' do
      expect { rake_task('protocol_keyword_team:exec').invoke }.to output("[SciNote] Start processing...\n[SciNote] Done!\n").to_stdout
    end
  end
end
