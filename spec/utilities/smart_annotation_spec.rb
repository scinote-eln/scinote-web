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

  describe '#search' do
    describe 'sa-projects' do
      it 'finds readable projects by name' do
        result = annotation.search(parent_type: 'sa-projects')
        expect(result[:items].map { |i| i[:id] }).to contain_exactly(project.id)
        expect(result[:items].first).to include(type: 'prj', id_encoded: project.id.base62_encode, code: project.code)
        expect(result[:limit_reached]).to be false
      end

      it 'skips archived projects' do
        project.update!(archived: true, archived_on: Time.zone.now)
        expect(annotation.search(parent_type: 'sa-projects')[:items]).to be_empty
      end

      it 'does not match other names' do
        expect(described_class.new(user, team, 'zzz').search(parent_type: 'sa-projects')[:items]).to be_empty
      end

      it 'lists the active experiments of a project when a parent is given' do
        result = annotation.search(parent_type: 'sa-projects', parent_id: project.id)
        expect(result[:items].map { |i| [i[:id], i[:type]] }).to contain_exactly([experiment.id, 'exp'])
      end

      it 'returns nothing for an archived parent project' do
        project.update_columns(archived: true)
        expect(annotation.search(parent_type: 'sa-projects', parent_id: project.id)[:items]).to be_empty
      end
    end

    describe 'sa-experiments' do
      it 'finds experiments in active projects' do
        result = annotation.search(parent_type: 'sa-experiments')
        expect(result[:items].map { |i| i[:id] }).to contain_exactly(experiment.id)
      end

      it 'skips archived experiments' do
        experiment.update_columns(archived: true)
        expect(annotation.search(parent_type: 'sa-experiments')[:items]).to be_empty
      end

      it 'skips experiments of archived projects' do
        project.update_columns(archived: true)
        expect(annotation.search(parent_type: 'sa-experiments')[:items]).to be_empty
      end

      it 'lists the active tasks of an experiment when a parent is given' do
        result = annotation.search(parent_type: 'sa-experiments', parent_id: experiment.id)
        expect(result[:items].map { |i| [i[:id], i[:type]] }).to contain_exactly([my_module.id, 'tsk'])
      end

      it 'returns nothing for an archived parent experiment' do
        experiment.update_columns(archived: true)
        expect(annotation.search(parent_type: 'sa-experiments', parent_id: experiment.id)[:items]).to be_empty
      end
    end

    describe 'sa-tasks' do
      it 'finds active tasks' do
        result = annotation.search(parent_type: 'sa-tasks')
        expect(result[:items].map { |i| i[:id] }).to contain_exactly(my_module.id)
      end

      it 'skips archived tasks' do
        my_module.update_columns(archived: true)
        expect(annotation.search(parent_type: 'sa-tasks')[:items]).to be_empty
      end

      it 'skips tasks of archived experiments' do
        experiment.update_columns(archived: true)
        expect(annotation.search(parent_type: 'sa-tasks')[:items]).to be_empty
      end
    end

    describe 'sa-repositories' do
      let(:repository) { create :repository, team: team, created_by: user, name: 'Alpha inventory' }
      let!(:row) { create :repository_row, repository: repository, created_by: user, name: 'Alpha <script>alert(1)</script>row' }
      let(:search) do
        ->(**args) { annotation.search(parent_type: 'sa-repositories', parent_id: repository.id, **args) }
      end

      before do
        create :repository_row, repository: repository, created_by: user, name: 'Other row'
        create :repository_row, :archived, repository: repository, created_by: user, name: 'Alpha archived'
      end

      it 'lists active repositories at the root' do
        result = annotation.search(parent_type: 'sa-repositories')
        expect(result[:items].map { |i| [i[:id], i[:type]] }).to contain_exactly([repository.id, 'rep'])
      end

      it 'returns encoded, sanitized hashes of active matching rows' do
        items = search.call[:items]
        expect(items.size).to eq 1
        expect(items.first).to include(id: row.id, id_encoded: row.id.base62_encode, code: row.code, type: 'rep_item')
        expect(items.first[:name]).to include('Alpha')
        expect(items.first[:name]).not_to include('<script>')
        expect(items.first).not_to have_key(:row_assigned)
      end

      context 'with a task id' do
        it 'marks rows as not assigned' do
          item = search.call(assignable_my_module_id: my_module.id)[:items].first
          expect(item).to include(row_assigned: false, my_module_id: my_module.id, repository_row_id: row.id)
        end

        it 'marks assigned rows' do
          create :mm_repository_row, my_module: my_module, repository_row: row, assigned_by: user
          item = search.call(assignable_my_module_id: my_module.id)[:items].first
          expect(item[:row_assigned]).to be true
        end
      end
    end

    it 'returns no items for an unknown parent type' do
      expect(annotation.search(parent_type: 'sa-unknown')).to eq(items: [], limit_reached: false)
    end
  end

  describe '#global_search' do
    it 'combines matches of every type, newest first' do
      result = annotation.global_search
      expect(result[:items].map { |i| i[:type] }).to include('prj', 'exp', 'tsk')
      timestamps = result[:items].map { |i| i[:updated_at] }
      expect(timestamps).to eq(timestamps.sort.reverse)
    end

    it 'flags when the result limit is exceeded' do
      stub_const('SmartAnnotation::LIMIT', 1)
      result = annotation.global_search
      expect(result[:items].size).to eq 1
      expect(result[:limit_reached]).to be true
    end
  end
end
