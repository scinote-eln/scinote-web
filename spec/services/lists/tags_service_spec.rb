# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::TagsService do
  let(:user) { create :user, full_name: 'Zed Creator' }
  let(:other_user) { create :user, full_name: 'Abe Creator' }
  let(:team) { create :team, created_by: user }
  let!(:tag_a) { create :tag, team: team, created_by: user, name: 'Alpha', color: '#111111' }
  let!(:tag_b) { create :tag, team: team, created_by: other_user, name: 'Beta', color: '#222222' }
  let!(:tag_c) { create :tag, team: team, created_by: user, name: 'Gamma', color: '#333333' }

  def call(extra = {})
    described_class.new(team.tags, ActionController::Parameters.new({ page: 1, per_page: 10 }.merge(extra))).call
  end

  before do
    project = create :project, team: team, created_by: user
    experiment = create :experiment, project: project, created_by: user
    mm = create :my_module, experiment: experiment, created_by: user
    mm2 = create :my_module, experiment: experiment, created_by: user
    Tagging.create!(tag: tag_c, taggable: mm, created_by: user)
    Tagging.create!(tag: tag_c, taggable: mm2, created_by: user)
    Tagging.create!(tag: tag_a, taggable: mm, created_by: user)
  end

  it 'returns the team tags with taggings counts' do
    result = call
    expect(result.map(&:id)).to match_array([tag_a.id, tag_b.id, tag_c.id])
    counts = result.to_h { |t| [t.name, t['taggings_count']] }
    expect(counts).to eq('Alpha' => 1, 'Beta' => 0, 'Gamma' => 2)
  end

  it 'filters by name search' do
    expect(call(search: 'amm').map(&:name)).to eq ['Gamma']
  end

  it 'sorts by name' do
    expect(call(order: { column: 'name', dir: 'asc' }).map(&:name)).to eq %w(Alpha Beta Gamma)
    expect(call(order: { column: 'name', dir: 'desc' }).map(&:name)).to eq %w(Gamma Beta Alpha)
  end

  it 'sorts by color' do
    expect(call(order: { column: 'color', dir: 'desc' }).map(&:name)).to eq %w(Gamma Beta Alpha)
  end

  it 'sorts by taggings count' do
    expect(call(order: { column: 'taggings_count', dir: 'desc' }).map(&:name)).to eq %w(Gamma Alpha Beta)
    expect(call(order: { column: 'taggings_count', dir: 'asc' }).map(&:name)).to eq %w(Beta Alpha Gamma)
  end

  it 'sorts by creator name' do
    expect(call(order: { column: 'created_by', dir: 'asc' }).first.name).to eq 'Beta'
  end

  it 'keeps the default order for an unknown column' do
    expect(call(order: { column: 'bogus', dir: 'asc' }).map(&:id)).to match_array([tag_a.id, tag_b.id, tag_c.id])
  end

  it 'paginates' do
    expect(call(per_page: 2, page: 2, order: { column: 'name', dir: 'asc' }).map(&:name)).to eq ['Gamma']
  end
end
