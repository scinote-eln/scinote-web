# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::TeamsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:team) { create :team, created_by: user }
  let(:inventory_creator) { create :user }
  let(:other_team) { create :team, created_by: inventory_creator }
  let(:columns_role) do
    create :user_role, name: 'Inventory columns updater', created_by: user, last_modified_by: user,
                       permissions: [RepositoryPermissions::READ, RepositoryPermissions::COLUMNS_UPDATE]
  end
  let(:enforce_role) do
    create :user_role, name: 'Inventory table enforcer', created_by: user, last_modified_by: user,
                       permissions: [RepositoryPermissions::READ, RepositoryPermissions::ENFORCE_TABLE_STATE]
  end
  let(:read_only_role) do
    create :user_role, name: 'Inventory reader', created_by: user, last_modified_by: user,
                       permissions: [RepositoryPermissions::READ]
  end
  let(:manage_role) do
    create :user_role, name: 'Inventory manager', created_by: user, last_modified_by: user,
                       permissions: [RepositoryPermissions::READ, RepositoryPermissions::MANAGE]
  end

  # The inventory is created by another user, so the only assignment the user has is the one given here.
  def inventory_assigned_to_user(role, *traits, name:, inventory_team: team)
    inventory = create :repository, *traits, name: name, team: inventory_team, created_by: inventory_creator
    create_user_assignment(inventory, role, user)
    inventory
  end

  before do
    user.update!(current_team_id: team.id)
    # Both flags are stubbed: the addon decorator reads a different env variable than core for deletion
    # prevention, and SCI-13751 will turn the inventory integrity stub into an env read.
    allow(Team).to receive(:deletion_prevention_enabled?).and_return(true)
    allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(true)
  end

  describe 'GET inventory_settings_repositories' do
    let(:action) { get :inventory_settings_repositories, params: { id: team.id }, format: :json }

    context 'when the user manages the team' do
      it 'renders the manageable inventories as [id, name] pairs sorted by name case-insensitively' do
        charlie = inventory_assigned_to_user(manage_role, name: 'Charlie stock')
        alpha = inventory_assigned_to_user(manage_role, name: 'alpha stock')
        beta = inventory_assigned_to_user(manage_role, name: 'Beta stock')
        inventory_assigned_to_user(columns_role, name: 'Columns-only stock')
        inventory_assigned_to_user(enforce_role, name: 'Enforce-only stock')
        inventory_assigned_to_user(read_only_role, name: 'Read-only stock')
        inventory_assigned_to_user(manage_role, :archived, name: 'Archived stock')
        inventory_assigned_to_user(manage_role, name: 'Foreign stock', inventory_team: other_team)
        shared = create :repository, name: 'Shared stock', team: other_team, created_by: inventory_creator
        create_team_assignment(shared, manage_role, team, inventory_creator)

        action

        expect(response).to have_http_status(:ok)
        expect(json[:data]).to eq([[alpha.id, 'alpha stock'], [beta.id, 'Beta stock'], [charlie.id, 'Charlie stock']])
      end

      it 'renders an empty list when no inventory is manageable' do
        inventory_assigned_to_user(read_only_role, name: 'Read-only stock')

        action

        expect(response).to have_http_status(:ok)
        expect(json[:data]).to eq([])
      end

      it 'lists the inventories of the requested team, not of the current team' do
        second_team = create :team, created_by: user
        inventory_assigned_to_user(manage_role, name: 'Current team stock', inventory_team: second_team)
        requested = inventory_assigned_to_user(manage_role, name: 'Requested team stock')
        user.update!(current_team_id: second_team.id)

        action

        expect(response).to have_http_status(:ok)
        expect(json[:data]).to eq([[requested.id, 'Requested team stock']])
      end
    end

    context 'when deletion prevention is disabled' do
      before do
        allow(Team).to receive(:deletion_prevention_enabled?).and_return(false)
        inventory_assigned_to_user(columns_role, name: 'Hidden stock')
      end

      it 'renders 403 without the inventory list' do
        action

        expect(response).to have_http_status(:forbidden)
        expect(json).to eq('style' => 'danger')
      end
    end

    context 'when inventory integrity is disabled' do
      before do
        allow(RepositoryBase).to receive(:inventory_integrity_enabled?).and_return(false)
        inventory_assigned_to_user(columns_role, name: 'Hidden stock')
      end

      it 'renders 403 without the inventory list' do
        action

        expect(response).to have_http_status(:forbidden)
        expect(json).to eq('style' => 'danger')
      end
    end

    context 'when the user cannot manage the team' do
      let(:action) { get :inventory_settings_repositories, params: { id: other_team.id }, format: :json }

      before do
        viewer_role = UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role)
        create_user_assignment(other_team, viewer_role, user, inventory_creator)
        inventory_assigned_to_user(columns_role, name: 'Hidden stock', inventory_team: other_team)
      end

      it 'renders 403 without the inventory list' do
        action

        expect(response).to have_http_status(:forbidden)
        expect(json).to eq('style' => 'danger')
      end
    end
  end
end
