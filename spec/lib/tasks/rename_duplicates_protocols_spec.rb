# frozen_string_literal: true

require 'rails_helper'

describe 'protocols:rename_duplicates_team_protocols' do
  include_context 'rake file loaded once', 'rename_duplicates_protocols'

  let(:team) { create :team }
  let(:user) { create :user }
  let(:other_user) { create :user }

  def task
    rake_task('protocols:rename_duplicates_team_protocols')
  end

  # Names are made equal with update_column to bypass the name validations.
  def build_protocol(type, name, created_at, team: self.team, added_by: user)
    protocol = create(:protocol, :in_repository_draft, team: team, added_by: added_by)
    protocol.update_columns(name: name, protocol_type: Protocol.protocol_types[type], created_at: created_at)
    protocol
  end

  context 'with duplicate public protocols in a team' do
    let!(:oldest) { build_protocol(:in_repository_public, 'Dup', 3.days.ago) }
    let!(:middle) { build_protocol(:in_repository_public, 'Dup', 2.days.ago) }
    let!(:newest) { build_protocol(:in_repository_public, 'Dup', 1.day.ago) }

    it 'keeps the oldest name and numbers the rest by creation order' do
      task.invoke

      expect(oldest.reload.name).to eq('Dup')
      expect(middle.reload.name).to eq('Dup (1)')
      expect(newest.reload.name).to eq('Dup (2)')
    end

    it 'does not rename same-named public protocols of another team' do
      other = build_protocol(:in_repository_public, 'Dup', 1.hour.ago, team: create(:team))
      task.invoke

      expect(other.reload.name).to eq('Dup')
    end
  end

  context 'with duplicate private protocols' do
    let!(:first) { build_protocol(:in_repository_private, 'Priv', 3.days.ago) }
    let!(:second) { build_protocol(:in_repository_private, 'Priv', 2.days.ago) }
    let!(:other_owner) { build_protocol(:in_repository_private, 'Priv', 1.day.ago, added_by: other_user) }

    it 'renames duplicates of the same author only' do
      task.invoke

      expect(first.reload.name).to eq('Priv')
      expect(second.reload.name).to eq('Priv (1)')
      expect(other_owner.reload.name).to eq('Priv')
    end
  end

  context 'with duplicate archived protocols' do
    let!(:first) { build_protocol(:in_repository_archived, 'Arch', 3.days.ago) }
    let!(:second) { build_protocol(:in_repository_archived, 'Arch', 2.days.ago) }
    let!(:third) { build_protocol(:in_repository_archived, 'Arch', 1.day.ago) }

    it 'renames duplicates of the same author' do
      task.invoke

      expect([first, second, third].map { |p| p.reload.name }).to eq(['Arch', 'Arch (1)', 'Arch (2)'])
    end
  end

  context 'without duplicates' do
    let!(:public_one) { build_protocol(:in_repository_public, 'Same', 2.days.ago) }
    let!(:private_one) { build_protocol(:in_repository_private, 'Same', 1.day.ago) }
    let!(:unlinked) { create :protocol, team: team }

    it 'leaves names untouched, also across protocol types' do
      expect { task.invoke }.not_to(change { [public_one, private_one, unlinked].map { |p| p.reload.name } })
    end
  end
end
