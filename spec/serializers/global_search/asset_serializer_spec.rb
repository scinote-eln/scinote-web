# frozen_string_literal: true

require 'rails_helper'

describe GlobalSearch::AssetSerializer do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:result) { create :result, my_module: my_module, user: user }
  let(:routes) { Rails.application.routes.url_helpers }
  let(:created_at) { Time.zone.parse('2030-03-14 09:30') }
  let(:asset) do
    create(:asset, team: team, created_at: created_at).tap do |record|
      File.open(Rails.root.join('spec/fixtures/files/test.jpg')) do |file|
        record.file.attach(io: file, filename: 'lab-notes.jpg')
      end
    end
  end

  # reload drops cached associations, so each example sees the current database state
  def serialize(record = asset)
    described_class.new(record.reload).attributes
  end

  context 'when the asset belongs to a result' do
    before { create :result_asset, result: result, asset: asset }

    it 'exposes the file name, icon and a date-only created_at' do
      attrs = serialize

      expect(attrs[:id]).to eq asset.id
      expect(attrs[:file_name]).to eq 'lab-notes.jpg'
      expect(attrs[:icon]).to eq 'sn-icon-result-image'
      expect(attrs[:created_at]).to eq I18n.l(created_at, format: :full_date)
      expect(attrs[:created_at]).not_to include('09:30')
    end

    it 'links the team to its dashboard' do
      expect(serialize[:team]).to eq(name: team.name, url: routes.dashboard_path(team: team))
    end

    it 'describes the experiment with its active view url' do
      expect(serialize[:experiment]).to eq(
        name: experiment.name,
        url: routes.my_modules_experiment_path(id: experiment.id, view_mode: 'active'),
        archived: false
      )
    end

    it 'marks the experiment as archived when its branch is archived' do
      experiment.update_column(:archived, true)

      expect(serialize[:experiment]).to eq(
        name: experiment.name,
        url: routes.my_modules_experiment_path(id: experiment.id, view_mode: 'archived'),
        archived: true
      )
    end

    it 'describes the task as the parent' do
      expect(serialize[:parent]).to eq(
        name: my_module.name,
        url: routes.my_module_results_path(my_module_id: my_module.id, view_mode: 'active'),
        type: 'task',
        archived: false
      )
    end

    it 'uses the archived results view for an archived result' do
      result.update_column(:archived, true)

      expect(serialize[:parent][:url]).to eq routes.my_module_results_path(my_module_id: my_module.id,
                                                                            view_mode: 'archived')
    end

    it 'has no repository information' do
      expect(serialize[:repository]).to eq(name: '')
    end
  end

  context 'when the asset belongs to a step of a task' do
    let(:step) { create :step, protocol: create(:protocol, my_module: my_module, team: team), user: user }

    before { create :step_asset, step: step, asset: asset }

    it 'describes the task as the parent with the protocols url' do
      expect(serialize[:parent]).to eq(
        name: my_module.name,
        url: routes.protocols_my_module_path(my_module.id, view_mode: 'active'),
        type: 'task',
        archived: false
      )
    end
  end

  context 'when the asset belongs to a step of a protocol template' do
    let(:template) { create :protocol, :in_public_repository, team: team, name: 'Template protocol' }
    let(:step) { create :step, protocol: template, user: user }

    before { create :step_asset, step: step, asset: asset }

    it 'describes the protocol template as the parent' do
      expect(serialize[:parent]).to eq(
        name: 'Template protocol',
        url: routes.protocol_path(template.id),
        type: 'protocol_template',
        archived: false
      )
    end
  end

  context 'when the asset belongs to an inventory item' do
    let!(:repository_value) { create :repository_asset_value, asset: asset }
    let(:row) { repository_value.repository_cell.repository_row }
    let(:repository) { row.repository }

    it 'describes the inventory item as the parent' do
      expect(serialize[:parent]).to eq(
        name: row.name,
        url: routes.repository_path(id: repository.id, landing_page: true, row_id: row.id),
        type: 'inventory_item',
        archived: false
      )
    end

    it 'describes the inventory with a plain url' do
      expect(serialize[:repository]).to eq(
        name: repository.name,
        url: routes.repository_path(id: repository.id, archived: false),
        archived: false
      )
    end

    it 'flags archived inventory items and their inventory' do
      row.update_column(:archived, true)

      expect(serialize[:parent]).to include(
        url: routes.repository_path(id: repository.id, landing_page: true, row_id: row.id, archived: true),
        archived: true
      )
      expect(serialize[:repository]).to eq(
        name: repository.name,
        url: routes.repository_path(id: repository.id, archived: true),
        archived: true
      )
    end
  end

  context 'when the asset has no parent' do
    it 'returns empty parent details and an empty repository' do
      expect(serialize).to include(
        parent: { name: nil, url: nil, type: nil, archived: nil },
        experiment: { name: '' },
        repository: { name: '' }
      )
    end
  end
end
