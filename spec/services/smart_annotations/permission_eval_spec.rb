require 'rails_helper'
require 'smart_annotations/permision_eval'

describe SmartAnnotations::PermissionEval do
  let(:subject) { described_class }
  let(:user) { create :user }
  let(:team) { create :team }
  let(:user_team) { create :user_team, user: user, team: team, role: 2 }
  let(:project) { create :project, name: 'my project' }
  let(:experiment) do
    create :experiment, name: 'my experiment',
                        project: project,
                        created_by: user,
                        last_modified_by: user
  end
  let(:task) { create :my_module, name: 'task', experiment: experiment }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:repository_item) { create :repository_row, repository: repository }

  describe '#validate_prj_permissions/2' do
    it 'returns a boolean' do
      value = subject.send(:validate_prj_permissions, user, project)
      expect(value).to be_in([true, false])
    end
  end

  describe '#validate_exp_permissions/2' do
    it 'returns a boolean' do
      value = subject.send(:validate_exp_permissions, user, experiment)
      expect(value).to be_in([true, false])
    end
  end

  describe '#validate_tsk_permissions/2' do
    it 'returns a boolean' do
      value = subject.send(:validate_tsk_permissions, user, task)
      expect(value).to be_in([true, false])
    end
  end

  describe '#validate_rep_item_permissions/2' do
    it 'returns a boolean' do
      value = subject.send(:validate_rep_item_permissions, user, repository_item)
      expect(value).to be_in([true, false])
    end
  end
end
