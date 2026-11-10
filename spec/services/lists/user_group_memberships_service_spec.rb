# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lists::UserGroupMembershipsService do
  let(:creator) { create :user }
  let(:team) { create :team, created_by: creator }
  let(:group) { create :user_group, team: team, created_by: creator }
  let(:u1) { create :user, full_name: 'Anna Alpha', email: 'zz.anna@example.com' }
  let(:u2) { create :user, full_name: 'Boris Beta', email: 'aa.boris@example.com' }
  let!(:m1) { create :user_group_membership, user_group: group, user: u1, created_by: creator }
  let!(:m2) { create :user_group_membership, user_group: group, user: u2, created_by: creator }

  def call(extra = {})
    params = ActionController::Parameters.new({ page: 1, per_page: 10 }.merge(extra))
    described_class.new(group.user_group_memberships, params).call
  end

  it 'returns the group memberships with users' do
    create :user_group_membership, created_by: creator
    expect(call.map(&:id)).to match_array([m1.id, m2.id])
  end

  it 'filters by name or email' do
    expect(call(search: 'Anna').map(&:id)).to eq [m1.id]
    expect(call(search: 'aa.boris').map(&:id)).to eq [m2.id]
  end

  it 'sorts by name' do
    expect(call(order: { column: 'name', dir: 'desc' }).map(&:id)).to eq [m2.id, m1.id]
  end

  it 'sorts by email' do
    expect(call(order: { column: 'email', dir: 'asc' }).map(&:id)).to eq [m2.id, m1.id]
  end

  it 'sorts by created_at' do
    m1.update_columns(created_at: 2.days.ago)
    expect(call(order: { column: 'created_at', dir: 'asc' }).map(&:id)).to eq [m1.id, m2.id]
  end

  it 'ignores an unknown sort column' do
    expect(call(order: { column: 'bogus', dir: 'asc' }).map(&:id)).to match_array([m1.id, m2.id])
  end

  it 'paginates' do
    expect(call(per_page: 1, page: 2, order: { column: 'name', dir: 'asc' }).map(&:id)).to eq [m2.id]
  end
end
