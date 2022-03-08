# frozen_string_literal: true

require 'rails_helper'

describe 'RepositoryPermissions' do
  include Canaid::Helpers::PermissionsHelper

  let(:user) { create :user, current_team_id: team.id }
  let(:repository) { build :repository, team: team }
  let(:team) { create :team }
  let(:write_shared_repository) { create :repository, :write_shared }
  let(:read_shared_repository) { create :repository, :read_shared }

  describe 'create_repository_rows, manage_repository_rows, create_repository_columns' do
    context 'when team\'s repository' do
      it 'should be true for admin' do
        create :user_team, :admin, user: user, team: team

        expect(can_create_repository_rows?(user, repository)).to be_truthy
      end

      it 'should be true for normal_user' do
        create :user_team, :normal_user, user: user, team: team

        expect(can_create_repository_rows?(user, repository)).to be_truthy
      end

      it 'should be false for guest' do
        create :user_team, :guest, user: user, team: team

        expect(can_create_repository_rows?(user, repository)).to be_falsey
      end
    end

    context 'when shared repository' do
      let(:new_team) { create :team }
      let(:new_repository) { create :repository, team: new_team }

      it 'should be true when have sharred repo with write' do
        create :user_team, :normal_user, user: user, team: team
        create :team_repository, :write, team: team, repository: new_repository

        expect(can_create_repository_rows?(user, new_repository)).to be_truthy
      end

      it 'should be false when have sharred repo with read' do
        create :user_team, :normal_user, user: user, team: team
        create :team_repository, :read, team: team, repository: new_repository

        expect(can_create_repository_rows?(user, new_repository)).to be_falsey
      end

      it 'should be false when do not have sharred repo' do
        create :user_team, :normal_user, user: user, team: team
        create :team_repository, :read, team: team

        expect(can_create_repository_rows?(user, new_repository)).to be_falsey
      end

      it 'should be false when have sharred repo with write but user is guest' do
        create :user_team, :guest, user: user, team: team
        create :team_repository, :write, team: team, repository: new_repository

        expect(can_create_repository_rows?(user, new_repository)).to be_falsey
      end
    end

    context 'when shared with all organization' do
      it 'should be true when repo has write permission' do
        create :user_team, :normal_user, user: user, team: team
        allow_any_instance_of(User).to receive(:current_team).and_return(team)

        expect(can_create_repository_rows?(user, write_shared_repository)).to be_truthy
      end

      it 'should be false when repo has read permission' do
        expect(can_create_repository_rows?(user, read_shared_repository)).to be_falsey
      end
    end
  end

  describe 'read_repository' do
    context 'when team\'s repository' do
      it 'should be true' do
        create :user_team, :normal_user, user: user, team: team

        expect(can_read_repository?(user, repository)).to be_truthy
      end
    end

    context 'when shared repository' do
      let(:new_team) { create :team }
      let(:new_repository) { create :repository, team: new_team }

      it 'should be true when have sharred repo with read' do
        create :user_team, :normal_user, user: user, team: team
        create :team_repository, :read, team: team, repository: new_repository

        expect(can_read_repository?(user, new_repository)).to be_truthy
      end

      it 'should be false when do not have sharred repo' do
        create :user_team, :normal_user, user: user, team: team
        create :team_repository, :read, team: team

        expect(can_read_repository?(user, new_repository)).to be_falsey
      end
    end

    context 'when shared with all organization' do
      it 'should be true when repo has write permission' do
        expect(can_read_repository?(user, write_shared_repository)).to be_truthy
      end

      it 'should be true when repo has read permission' do
        expect(can_read_repository?(user, read_shared_repository)).to be_truthy
      end
    end
  end
end
