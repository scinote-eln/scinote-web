# frozen_string_literal: true

require 'rails_helper'

describe ProtocolLinkedChildrenDatatable do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create_user_assignment(team, owner_role, user) }

  let(:original) { create :protocol, :in_repository_published_original, team: team, added_by: user, name: 'Original protocol' }
  let(:published_version) do
    create :protocol, :in_repository_published_version, team: team, parent: original, added_by: user,
                                                        name: 'Version 2', version_number: 2
  end
  let(:child_of_version) do
    create :protocol, :linked_to_repository, team: team, parent: published_version, name: 'Child of v2'
  end
  let(:child_of_original) do
    create :protocol, :linked_to_repository, team: team, parent: original, name: 'Child of original'
  end
  let(:other_original) { create :protocol, :in_repository_published_original, team: team, added_by: user, name: 'Other protocol' }
  let(:unrelated_child) do
    create :protocol, :linked_to_repository, team: team, parent: other_original, name: 'Unrelated child'
  end

  let(:params) do
    ActionController::Parameters.new(
      draw: '1', start: '0', length: '10',
      order: { '0' => { column: '0', dir: 'desc' } },
      columns: { '0' => { data: '0', orderable: 'true' } }
    )
  end
  let(:view) { double('view', params: params) }
  let(:controller) { double('controller') }
  let(:datatable) { described_class.new(view, original, user, controller) }

  describe 'column configuration' do
    it 'sorts and displays by protocol id only' do
      expect(datatable.sortable_columns).to eq ['Protocol.id']
      expect(datatable.sortable_displayed_columns).to eq ['0']
      expect(datatable.searchable_columns).to eq []
    end
  end

  describe '#get_raw_records' do
    it 'returns the linked children of the protocol and of its published versions' do
      child_of_version
      child_of_original
      unrelated_child

      records = datatable.send(:get_raw_records)

      expect(records).to contain_exactly(child_of_version, child_of_original)
    end

    it 'returns only the children linked to the requested published version' do
      child_of_version
      child_of_original
      params[:version] = '2'

      records = datatable.send(:get_raw_records)

      expect(records).to contain_exactly(child_of_version)
    end

    it 'raises not found for a version the protocol does not have' do
      params[:version] = '9'

      expect { datatable.send(:get_raw_records) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#data' do
    it 'returns one row per linked child with the child id and breadcrumb html' do
      child_of_version
      child_of_original
      rendered = []
      allow(controller).to receive(:render_to_string) do |args|
        rendered << args
        "<#{args[:partial].split('/').last}>"
      end

      data = datatable.send(:data)

      expect(data.map { |row| row['DT_RowId'] }).to contain_exactly(child_of_version.id, child_of_original.id)
      expect(data.map { |row| row['1'] }).to all(start_with("<ol class='breadcrumb'>"))
      expect(rendered.size).to eq 6
    end
  end

  describe '#record_html' do
    let(:my_module_project) { child_of_version.my_module.experiment.project }

    before do
      allow(controller).to receive(:render_to_string) do |args|
        "<#{args[:partial].split('/').last}>"
      end
    end

    it 'renders the project, experiment and task breadcrumb in order' do
      expect(datatable.send(:record_html, child_of_version)).to eq(
        "<ol class='breadcrumb'>" \
        "<li><span class='sn-icon sn-icon-projects'></span>&nbsp;<project_text></li>" \
        "<li><i class='sn-icon sn-icon-experiment'></i>&nbsp;<experiment_text></li>" \
        "<li><span class='sn-icon sn-icon-task'></span>&nbsp;<my_module_text></li>" \
        '</ol>'
      )
    end

    it 'passes the record own project, experiment and task to the partials' do
      datatable.send(:record_html, child_of_version)
      project_call = { partial: 'search/results/partials/project_text',
                       locals: { project: my_module_project, link_to_page: :show },
                       formats: :html }
      my_module = child_of_version.my_module
      task_call = { partial: 'search/results/partials/my_module_text',
                    locals: { my_module: my_module, link_to_page: :protocols },
                    formats: :html }

      expect(controller).to have_received(:render_to_string).with(project_call)
      expect(controller).to have_received(:render_to_string).with(task_call)
    end
  end
end
