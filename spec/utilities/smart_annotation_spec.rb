# frozen_string_literal: true

require 'rails_helper'

describe SmartAnnotation do
  let!(:user) { create :user }
  let!(:team) { create :team, :change_user_team, created_by: user }
  let!(:project) { create :project, name: 'my project', team: team, created_by: user }
  let!(:experiment) { create :experiment, project: project, created_by: user }
  let!(:task) { create :my_module, name: 'task', experiment: experiment, created_by: user }
  let!(:other_task) { create :my_module, name: 'other task', experiment: experiment, created_by: user }

  let!(:protocol) { create :protocol, team: team, my_module: task }
  let!(:step) { create :step, protocol: protocol }
  let!(:step_asset) { create :step_asset, step: step }
  let!(:step_file) do
    asset = Asset.find(step_asset.asset_id)
    asset.file.attach(io: Rails.root.join('spec/fixtures/files/test.jpg').open, filename: 'unique_step_file.jpg')
    asset
  end

  let!(:result) { create :result, my_module: task, user: user }
  let!(:result_asset) { create :result_asset, result: result }
  let(:result_file) { Asset.find(result_asset.asset_id) }

  let!(:other_protocol) { create :protocol, team: team, my_module: other_task }
  let!(:other_step) { create :step, protocol: other_protocol }
  let!(:other_step_asset) { create :step_asset, step: other_step }

  subject { described_class.new(user, team, query) }
  let(:query) { nil }

  describe '#search with parent_type sa-task-files' do
    it 'returns files belonging to the task, through both its steps and its results' do
      result_ids = subject.search(parent_type: 'sa-task-files', parent_id: task.id)[:items].pluck(:id)
      expect(result_ids).to contain_exactly(step_file.id, result_file.id)
    end

    it 'does not return files belonging to a different task' do
      result_ids = subject.search(parent_type: 'sa-task-files', parent_id: task.id)[:items].pluck(:id)
      expect(result_ids).not_to include(other_step_asset.asset_id)
    end

    context 'filtering by file name' do
      let(:query) { 'unique_step' }

      it 'returns only the matching file' do
        result_ids = subject.search(parent_type: 'sa-task-files', parent_id: task.id)[:items].pluck(:id)
        expect(result_ids).to eq([step_file.id])
      end
    end

    context 'filtering by asset code' do
      let(:query) { step_file.code }

      it 'returns only the matching file' do
        result_ids = subject.search(parent_type: 'sa-task-files', parent_id: task.id)[:items].pluck(:id)
        expect(result_ids).to eq([step_file.id])
      end
    end
  end

  describe '#global_search' do
    it 'includes files among the other annotatable types' do
      result_ids = subject.global_search[:items].select { |i| i[:type] == 'file' }.pluck(:id)
      expect(result_ids).to contain_exactly(step_file.id, result_file.id, other_step_asset.asset_id)
    end

    context 'filtering by asset code' do
      let(:query) { step_file.code }

      it 'returns only the matching file' do
        items = subject.global_search[:items]
        expect(items.pluck(:id)).to eq([step_file.id])
        expect(items.first[:type]).to eq('file')
      end
    end
  end
end
