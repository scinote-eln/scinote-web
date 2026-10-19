# frozen_string_literal: true

require 'rails_helper'

describe Toolbars::RepositoryRowsService do
  let!(:viewer_role) { create :viewer_role }
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:row) { create :repository_row, repository: repository, created_by: user }
  let(:archived_row) { create :repository_row, :archived, repository: repository, created_by: user }

  before do
    user.update!(current_team_id: team.id)
    allow(Repository).to receive(:equipment_booking_enabled?).and_return(false)
  end

  def actions_for(*rows)
    described_class.new(user, repository_row_ids: rows.map(&:id)).actions
  end

  def names(*rows)
    actions_for(*rows).map { |a| a[:name] }
  end

  it 'returns no actions without rows' do
    expect(described_class.new(user, repository_row_ids: []).actions).to eq []
  end

  it 'raises when rows are from different repositories' do
    other_row = create :repository_row, repository: create(:repository, team: team, created_by: user)
    expect { described_class.new(user, repository_row_ids: [row.id, other_row.id]) }
      .to raise_error(RepositoryMismatchError)
  end

  it 'returns actions for active rows' do
    expect(names(row)).to eq %w(assign duplicate export_group printLabel archive)
  end

  it 'returns actions for archived rows' do
    expect(names(archived_row)).to eq %w(restore export_group printLabel delete)
  end

  it 'groups export actions' do
    group = actions_for(row).find { |a| a[:name] == 'export_group' }
    expect(group[:actions].map { |a| a[:name] }).to eq(%w(exportRows))
  end

  it 'adds the createEvent action for a single row when booking is enabled' do
    allow(Repository).to receive(:equipment_booking_enabled?).and_return(true)
    without_partial_double_verification do
      # permission only exists when the equipment booking addon is loaded
      allow_any_instance_of(described_class).to receive(:can_create_equipment_bookings?).and_return(true)
    end
    expect(names(row)).to include('createEvent')
  end

  it 'does not add createEvent for multiple rows' do
    allow(Repository).to receive(:equipment_booking_enabled?).and_return(true)
    without_partial_double_verification do
      # permission only exists when the equipment booking addon is loaded
      allow_any_instance_of(described_class).to receive(:can_create_equipment_bookings?).and_return(true)
    end
    expect(names(row, create(:repository_row, repository: repository, created_by: user))).not_to include('createEvent')
  end

  it 'hides write actions from a viewer' do
    UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
    expect(names(row)).to eq %w(assign export_group printLabel)
  end
end
