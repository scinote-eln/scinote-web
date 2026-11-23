# frozen_string_literal: true

require 'rails_helper'

describe Repository, type: :model do
  let(:repository) { build :repository }

  it 'is valid' do
    expect(repository).to be_valid
  end

  it 'should be of class Repository' do
    expect(subject.class).to eq Repository
  end

  describe 'Database table' do
    it { should have_db_column :team_id }
    it { should have_db_column :created_by_id }
    it { should have_db_column :name }
    it { should have_db_column :created_at }
    it { should have_db_column :updated_at }
  end

  describe 'Relations' do
    it { should belong_to :team }
    it { should belong_to(:created_by).class_name('User') }
    it { should belong_to(:repository_template).optional }
    it { should have_many :repository_rows }
    it { should have_many :repository_table_states }
    it { should have_many :report_elements }
    it { should have_many(:team_shared_objects).dependent(:destroy) }
    it { should have_many(:teams_shared_with) }
  end

  describe 'Validations' do
    describe '#created_by' do
      it { is_expected.to validate_presence_of :created_by }
    end

    describe '#name' do
      it { is_expected.to validate_length_of(:name).is_at_most(Constants::NAME_MAX_LENGTH) }
      it { expect(repository).to validate_uniqueness_of(:name).scoped_to(:team_id).case_insensitive }
    end

    describe '#team' do
      it { is_expected.to validate_presence_of :team }
    end
  end

  describe 'Scopes' do
    let(:user) { create :user }

    describe '#active and #archived' do
      before do
        create :repository, created_by: user
        create :repository, :archived, created_by: user
      end

      it 'returns only active rows' do
        expect(Repository.active.count).to be_eql 1
      end

      it 'returns only archived rows' do
        expect(Repository.archived.count).to be_eql 1
      end

      it 'returns all rows' do
        expect(Repository.count).to be_eql 2
      end
    end
  end

  describe '.columns_manageable_by_user' do
    let(:user) { create :user }
    let(:inventory_creator) { create :user }
    let(:team) { create :team, created_by: user }
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

    # The inventory is created by another user, so the only assignment the user has is the one given here.
    def inventory_assigned_to_user(role, *traits, inventory_team: team)
      inventory = create :repository, *traits, team: inventory_team, created_by: inventory_creator
      create_user_assignment(inventory, role, user)
      inventory
    end

    it 'includes an active inventory where the role grants COLUMNS_UPDATE without ENFORCE_TABLE_STATE' do
      inventory = inventory_assigned_to_user(columns_role)

      expect(described_class.columns_manageable_by_user(user, team)).to contain_exactly(inventory)
    end

    it 'includes an active inventory where the role grants ENFORCE_TABLE_STATE without COLUMNS_UPDATE' do
      inventory = inventory_assigned_to_user(enforce_role)

      expect(described_class.columns_manageable_by_user(user, team)).to contain_exactly(inventory)
    end

    it 'lists an inventory once when the role grants both permissions' do
      both_role = create :user_role, name: 'Inventory column manager', created_by: user, last_modified_by: user,
                                     permissions: [RepositoryPermissions::READ,
                                                   RepositoryPermissions::COLUMNS_UPDATE,
                                                   RepositoryPermissions::ENFORCE_TABLE_STATE]
      inventory = inventory_assigned_to_user(both_role)

      expect(described_class.columns_manageable_by_user(user, team).to_a).to eq([inventory])
    end

    it 'excludes an inventory where the role grants neither permission' do
      manageable_inventory = inventory_assigned_to_user(columns_role)
      inventory_assigned_to_user(read_only_role)

      expect(described_class.columns_manageable_by_user(user, team)).to contain_exactly(manageable_inventory)
    end

    it 'excludes an archived inventory even when the role grants the permissions' do
      active_inventory = inventory_assigned_to_user(columns_role)
      inventory_assigned_to_user(columns_role, :archived)

      expect(described_class.columns_manageable_by_user(user, team)).to contain_exactly(active_inventory)
    end

    it 'includes an inventory of another team that is shared into the team with a permitted role' do
      shared_inventory = create :repository, team: other_team, created_by: inventory_creator
      create_team_assignment(shared_inventory, enforce_role, team, inventory_creator)

      expect(described_class.columns_manageable_by_user(user, team)).to contain_exactly(shared_inventory)
    end

    it 'excludes an inventory shared into the team with a role that grants neither permission' do
      manageable_inventory = inventory_assigned_to_user(columns_role)
      read_only_shared_inventory = create :repository, team: other_team, created_by: inventory_creator
      create_team_assignment(read_only_shared_inventory, read_only_role, team, inventory_creator)

      expect(described_class.columns_manageable_by_user(user, team)).to contain_exactly(manageable_inventory)
    end

    it 'excludes an inventory the user manages only in another team' do
      foreign_inventory = inventory_assigned_to_user(columns_role, inventory_team: other_team)

      expect(described_class.columns_manageable_by_user(user, team)).to be_empty
      expect(described_class.columns_manageable_by_user(user, other_team)).to contain_exactly(foreign_inventory)
    end

    it 'uses the permission team of the user when no teams are given' do
      inventory = inventory_assigned_to_user(enforce_role)
      inventory_assigned_to_user(columns_role, inventory_team: other_team)
      user.update!(current_team_id: team.id)

      expect(described_class.columns_manageable_by_user(user)).to contain_exactly(inventory)
    end
  end

  describe '.copy' do
    let(:user) { create :user }
    let(:repository) { create :repository, created_by: user }

    it 'calls create activity for copying inventory' do
      expect(Activities::CreateActivityService)
        .to(receive(:call).with(hash_including(activity_type: :copy_inventory)))

      repository.copy(user, 'name for copied repo')
    end

    it 'adds activity in DB' do
      expect { repository.copy(user, 'name for copied repo') }
        .to(change { Activity.count })
    end
  end

  describe '.within_global_limits?' do
    let(:user) { create :user }

    context 'when have an archived repository' do
      before do
        Rails.configuration.x.global_repositories_limit = 2
        create :repository, created_by: user
        create :repository, :archived, created_by: user
      end

      after do
        Rails.configuration.x.global_repositories_limit = 0
      end

      it 'includes archived repositories in condition and returns false' do
        expect(described_class.within_global_limits?).to be_falsey
      end
    end
  end

  describe '.within_team_limits?' do
    let(:user) { create :user }

    context 'when have an archived repository' do
      before do
        Rails.configuration.x.team_repositories_limit = 2
        create :repository, team: team, created_by: user
        create :repository, :archived, team: team, created_by: user
      end

      after do
        Rails.configuration.x.team_repositories_limit = 0
      end

      let(:team) { create :team, created_by: user }

      it 'includes archived repositories in condition and returns false' do
        expect(described_class.within_team_limits?(team)).to be_falsey
      end
    end
  end
end
