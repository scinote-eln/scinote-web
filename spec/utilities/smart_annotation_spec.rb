# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotation do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:project) do
    create :project, team: team, created_by: user, name: 'Alpha project',
                     default_public_user_role_id: owner_role.id
  end
  let!(:experiment) { create :experiment, project: project, created_by: user, name: 'Alpha experiment' }
  let!(:my_module) { create :my_module, experiment: experiment, created_by: user, name: 'Alpha task' }
  let(:query) { 'Alpha' }
  let(:annotation) { described_class.new(user, team, query) }

  before { user.update!(current_team_id: team.id) }

  describe '#projects' do
    it 'finds readable projects by name' do
      expect(annotation.projects).to contain_exactly(project)
    end

    it 'skips archived projects' do
      project.update!(archived: true, archived_on: Time.zone.now)
      expect(annotation.projects).to be_empty
    end

    it 'does not match other names' do
      expect(described_class.new(user, team, 'zzz').projects).to be_empty
    end
  end

  describe '#experiments' do
    it 'finds experiments in active projects' do
      expect(annotation.experiments).to contain_exactly(experiment)
    end

    it 'skips archived experiments' do
      experiment.update_columns(archived: true)
      expect(annotation.experiments).to be_empty
    end

    it 'skips experiments of archived projects' do
      project.update_columns(archived: true)
      expect(annotation.experiments).to be_empty
    end
  end

  describe '#my_modules' do
    it 'finds active tasks' do
      expect(annotation.my_modules).to contain_exactly(my_module)
    end

    it 'skips archived tasks' do
      my_module.update_columns(archived: true)
      expect(annotation.my_modules).to be_empty
    end

    it 'skips tasks of archived experiments' do
      experiment.update_columns(archived: true)
      expect(annotation.my_modules).to be_empty
    end
  end

  describe '#repository_rows' do
    let(:repository) { create :repository, team: team, created_by: user }
    let!(:row) { create :repository_row, repository: repository, created_by: user, name: 'Alpha <b>row' }
    let(:query) { 'Alpha' }

    before do
      create :repository_row, repository: repository, created_by: user, name: 'Other row'
      create :repository_row, :archived, repository: repository, created_by: user, name: 'Alpha archived'
    end

    it 'returns encoded, escaped hashes of active matching rows' do
      result = annotation.repository_rows(repository, nil)
      expect(result.size).to eq 1
      expect(result.first).to include(id: row.id, id_encoded: row.id.base62_encode, code: row.code)
      expect(result.first[:name]).to include('Alpha')
      expect(result.first[:name]).not_to include('<b>')
      expect(result.first).not_to have_key(:row_assigned)
    end

    context 'with a task id' do
      it 'marks rows as not assigned' do
        result = annotation.repository_rows(repository, my_module.id)
        expect(result.first).to include(row_assigned: false, my_module_id: my_module.id)
      end

      it 'marks assigned rows' do
        create :mm_repository_row, my_module: my_module, repository_row: row, assigned_by: user
        result = annotation.repository_rows(repository, my_module.id)
        expect(result.first[:row_assigned]).to be true
      end
    end
  end
end
