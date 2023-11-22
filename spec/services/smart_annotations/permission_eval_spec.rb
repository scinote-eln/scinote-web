# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotations::PermissionEval do
  let(:subject) { described_class }
  let(:user) { create :user }
  let(:another_user) { create :user }
  let(:team) { create :team, :change_user_team, created_by: user }
  let(:another_team) { create :team }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }
  let(:project) { create :project, name: 'my project', team: team }
  let!(:user_project) { create :user_project, project: project, user: user }
  let!(:user_assignment) do
    create :user_assignment,
           assignable: project,
           user: user,
           user_role: UserRole.find_by(name: I18n.t('user_roles.predefined.owner')),
           assigned_by: user
  end
  let(:experiment) do
    create :experiment, name: 'my experiment',
                        project: project,
                        created_by: user,
                        last_modified_by: user
  end
  let(:task) { create :my_module, name: 'task', experiment: experiment, created_by: experiment.created_by }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:repository_item) { create :repository_row, repository: repository }

  describe '#validate_prj_permissions/2' do
    it 'returns a boolean' do
      value = subject.__send__(:validate_prj_permissions, user, team, project)
      expect(value).to be_in([true, false])
    end

    it 'returns false on wrong team' do
      value = subject.__send__(:validate_prj_permissions, user, another_team, project)
      expect(value).to be false
    end

    it 'returns true on the same team' do
      value = subject.__send__(:validate_prj_permissions, user, team, project)
      expect(value).to be true
    end
  end

  describe '#validate_exp_permissions/2' do
    it 'returns a boolean' do
      value = subject.__send__(:validate_exp_permissions, user, team, experiment)
      expect(value).to be_in([true, false])
    end

    it 'returns false on wrong team' do
      value = subject.__send__(:validate_exp_permissions, user, another_team, experiment)
      expect(value).to be false
    end

    it 'returns true on the same team' do
      value = subject.__send__(:validate_exp_permissions, user, team, experiment)
      expect(value).to be true
    end
  end

  describe '#validate_tsk_permissions/2' do
    it 'returns a boolean' do
      value = subject.__send__(:validate_tsk_permissions, user, team, task)
      expect(value).to be_in([true, false])
    end

    it 'returns false on wrong team' do
      value = subject.__send__(:validate_tsk_permissions, user, another_team, task)
      expect(value).to be false
    end

    it 'returns true on the same team' do
      value = subject.__send__(:validate_tsk_permissions, user, team, task)
      expect(value).to be true
    end
  end

  describe '#validate_rep_item_permissions/2' do
    it 'returns a boolean' do
      value = subject.__send__(:validate_rep_item_permissions, user, team, repository_item)
      expect(value).to be_in([true, false])
    end

    it 'returns false on wrong user' do
      value = subject.__send__(:validate_rep_item_permissions, another_user, another_team, repository_item)
      expect(value).to be false
    end

    it 'returns true on the same team' do
      value = subject.__send__(:validate_rep_item_permissions, user, team, repository_item)
      expect(value).to be true
    end

    context 'when user can access repository from another team, but not with the current' do
      it do
        # Add anoteher user also as a member of team whos owes repository with this item
        create_user_assignment(team, owner_role, another_user)

        value = subject.__send__(:validate_rep_item_permissions, another_user, another_team, repository_item)
        expect(value).to be false
      end
    end
  end
end
