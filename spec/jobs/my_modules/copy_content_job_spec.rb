# frozen_string_literal: true

require 'rails_helper'

describe MyModules::CopyContentJob do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:source_my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:target_my_module) { create :my_module, experiment: experiment, created_by: user, provisioning_status: :in_progress }

  let!(:step) { create :step, protocol: source_my_module.protocol, user: user }
  let!(:result) { create :result, my_module: source_my_module, user: user, attachments_locked: true }
  let!(:unlinked_result) { create :result, my_module: source_my_module, user: user }
  let!(:archived_result) { create :result, :archived, my_module: source_my_module, user: user }

  let!(:locked_result_text) do
    result_text = create :result_text, result: result, locked: true
    create :result_orderable_element, result: result, orderable: result_text, position: 0
    result_text
  end
  let!(:unlocked_result_text) do
    result_text = create :result_text, result: result
    create :result_orderable_element, result: result, orderable: result_text, position: 1
    result_text
  end
  let!(:locked_table) do
    table = build :table, team: team, created_by: user, locked: true
    table.build_result_table(result: result)
    table.save!
    create :result_orderable_element, result: result, orderable: table.result_table, position: 2
    table
  end
  let!(:locked_asset) do
    asset = create :asset, team: team, locked: true
    create :result_asset, result: result, asset: asset
    asset
  end
  let!(:step_result) { create :step_result, step: step, result: result, created_by: user }

  let(:copied_result) { target_my_module.results.find_by(name: result.name) }

  def perform(copy_results:)
    described_class.perform_now(user.id, source_my_module.id, target_my_module.id, copy_results: copy_results)
    target_my_module.reload
  end

  context 'when copy_results is false' do
    it 'copies the protocol without results' do
      perform(copy_results: false)

      expect(target_my_module.provisioning_status).to eq 'done'
      expect(target_my_module.protocol.steps.pluck(:name)).to eq [step.name]
      expect(target_my_module.results).to be_empty
    end
  end

  context 'when copy_results is true' do
    before { perform(copy_results: true) }

    it 'finishes provisioning' do
      expect(target_my_module.provisioning_status).to eq 'done'
    end

    it 'copies only active results' do
      expect(target_my_module.results.pluck(:name)).to contain_exactly(result.name, unlinked_result.name)
    end

    it 'copies result elements' do
      expect(copied_result.result_texts.pluck(:name)).to contain_exactly(locked_result_text.name, unlocked_result_text.name)
      expect(copied_result.tables.pluck(:name)).to eq [locked_table.name]
      expect(copied_result.assets.count).to eq 1
    end

    it 'copies locks on result and its elements' do
      expect(copied_result.attachments_locked).to be true
      expect(copied_result.result_texts.find_by(name: locked_result_text.name).locked).to be true
      expect(copied_result.result_texts.find_by(name: unlocked_result_text.name).locked).to be false
      expect(copied_result.tables.first.locked).to be true
      expect(copied_result.assets.first.locked).to be true
    end

    it 'links copied results to copied steps' do
      copied_step = target_my_module.protocol.steps.find_by(name: step.name)

      expect(copied_step.results).to eq [copied_result]
      expect(target_my_module.results.find_by(name: unlinked_result.name).steps).to be_empty
    end

    it 'keeps source step links intact' do
      expect(step.reload.results).to eq [result]
    end
  end
end
