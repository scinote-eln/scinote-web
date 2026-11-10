# frozen_string_literal: true

require 'rails_helper'

describe Tasks::SamplesToRepositoryMigrationService do
  include_context 'legacy samples tables'

  let(:user) { create(:user) }
  let(:team) { create(:team, created_by: user) }
  let(:repository) { create(:repository, team: team, created_by: user) }
  let(:service) { described_class }

  describe '.prepare_repository' do
    it 'creates a repository called Samples owned by the team creator' do
      result = nil
      expect { result = service.prepare_repository(team) }.to change { team.repositories.count }.by(1)

      expect(result).to be_persisted
      expect(result.name).to eq 'Samples'
      expect(result.created_by).to eq user
    end

    it 'numbers the name when a repository called Samples already exists' do
      create(:repository, team: team, created_by: user, name: 'Samples')
      first_copy = service.prepare_repository(team)
      second_copy = service.prepare_repository(team)

      expect(first_copy.name).to eq 'Samples (1)'
      expect(second_copy.name).to eq 'Samples (2)'
    end
  end

  describe '.prepare_text_value_custom_columns' do
    it 'creates one text column per custom field of the team only' do
      insert_legacy(:custom_fields, name: 'Concentration', team_id: team.id, user_id: user.id,
                                    created_at: Time.utc(2020, 1, 1), updated_at: Time.utc(2020, 1, 2))
      insert_legacy(:custom_fields, name: 'Volume', team_id: team.id, user_id: user.id,
                                    created_at: Time.utc(2020, 1, 1), updated_at: Time.utc(2020, 1, 2))
      insert_legacy(:custom_fields, name: 'Foreign', team_id: create(:team).id, user_id: user.id,
                                    created_at: Time.utc(2020, 1, 1), updated_at: Time.utc(2020, 1, 2))

      columns = service.prepare_text_value_custom_columns(team, repository)

      expect(columns.map(&:name)).to match_array(%w(Concentration Volume))
      expect(columns).to all(have_attributes(repository: repository, data_type: 'RepositoryTextValue',
                                             created_by_id: user.id))
      expect(columns.first.created_at).to eq Time.utc(2020, 1, 1)
    end

    it 'falls back to the repository creator when the custom field has no user' do
      insert_legacy(:custom_fields, name: 'Orphan', team_id: team.id, user_id: nil)

      # bug: service line 30 uses fetch('user_id') { default }, which returns the nil of the existing key
      pending 'bug: custom field without user_id is not defaulted'
      columns = service.prepare_text_value_custom_columns(team, repository)

      expect(columns.map(&:created_by_id)).to eq [user.id]
    end

    it 'returns no columns when the team has no custom fields' do
      expect(service.prepare_text_value_custom_columns(team, repository)).to eq []
    end
  end

  describe '.prepare_list_value_custom_columns_with_list_items' do
    include_context 'clock supporting to_s(:db)'

    before do
      insert_legacy(:sample_groups, name: 'Group A', color: '#ff0000', team_id: team.id,
                                    created_by_id: user.id, last_modified_by_id: user.id)
      insert_legacy(:sample_groups, name: 'Group B', color: '#00ff00', team_id: team.id,
                                    created_by_id: nil, last_modified_by_id: nil)
      insert_legacy(:sample_types, name: 'Plasma', team_id: team.id,
                                   created_by_id: user.id, last_modified_by_id: user.id)
      insert_legacy(:sample_types, name: 'Other team type', team_id: create(:team).id,
                                   created_by_id: user.id, last_modified_by_id: user.id)
    end

    it 'creates the group, type and color columns and fills the list items from the legacy tables' do
      group, type, color = service.prepare_list_value_custom_columns_with_list_items(team, repository)

      expect([group.name, group.data_type]).to eq %w(Sample\ group RepositoryListValue)
      expect([type.name, type.data_type]).to eq %w(Sample\ type RepositoryListValue)
      expect([color.name, color.data_type]).to eq ['Sample group color hex', 'RepositoryTextValue']
      expect(group.repository_list_items.pluck(:data)).to match_array(['Group A', 'Group B'])
      expect(type.repository_list_items.pluck(:data)).to eq ['Plasma']
    end

    it 'falls back to the team creator when a legacy item has no author' do
      group, = service.prepare_list_value_custom_columns_with_list_items(team, repository)

      item = group.repository_list_items.find_by(data: 'Group B')
      expect([item.created_by_id, item.last_modified_by_id]).to eq [user.id, user.id]
    end
  end

  describe '.fetch_all_team_samples' do
    it 'returns the samples of the team ordered by id with type and group names' do
      type_id = insert_legacy(:sample_types, name: 'Plasma', team_id: team.id)
      group_id = insert_legacy(:sample_groups, name: 'Group A', color: '#ff0000', team_id: team.id)
      second = insert_legacy(:samples, name: 'Second', user_id: user.id, team_id: team.id,
                                       sample_type_id: type_id, sample_group_id: group_id)
      first = insert_legacy(:samples, name: 'First', team_id: team.id)
      insert_legacy(:samples, name: 'Foreign', team_id: create(:team).id)

      rows = service.fetch_all_team_samples(team)

      expect(rows.map { |r| r['sample_id'] }).to eq [second, first].sort
      by_name = rows.index_by { |r| r['sample_name'] }
      expect(by_name['Second']).to include('sample_created_by_id' => user.id, 'sample_type_name' => 'Plasma',
                                           'sample_group_name' => 'Group A', 'sample_group_color' => '#ff0000')
      expect(by_name['First']).to include('sample_type_name' => nil, 'sample_group_name' => nil)
    end
  end

  describe '.get_sample_custom_fields and .get_assigned_sample_module' do
    let(:my_module) { create(:my_module) }
    let!(:sample_id) { insert_legacy(:samples, name: 'S', team_id: team.id) }

    it 'returns the custom field values of a sample with the column name' do
      field_id = insert_legacy(:custom_fields, name: 'Concentration', team_id: team.id)
      insert_legacy(:sample_custom_fields, sample_id: sample_id, custom_field_id: field_id, value: '5 mg')
      other_sample = insert_legacy(:samples, name: 'T', team_id: team.id)
      insert_legacy(:sample_custom_fields, sample_id: other_sample, custom_field_id: field_id, value: 'other')

      result = service.get_sample_custom_fields(sample_id)

      expect(result.map { |r| r.slice('column_name_reference', 'value') })
        .to eq [{ 'column_name_reference' => 'Concentration', 'value' => '5 mg' }]
    end

    it 'returns the task assignments of a sample' do
      insert_legacy(:sample_my_modules, sample_id: sample_id, my_module_id: my_module.id, assigned_by_id: user.id)

      expect(service.get_assigned_sample_module(sample_id))
        .to eq [{ 'my_module_id' => my_module.id, 'assigned_by_id' => user.id }]
    end

    it 'returns empty lists for a sample without custom fields and assignments' do
      expect(service.get_sample_custom_fields(sample_id)).to eq []
      expect(service.get_assigned_sample_module(sample_id)).to eq []
    end
  end

  describe '.get_custom_columns' do
    include_context 'clock supporting to_s(:db)'

    it 'combines the custom field columns with the group, color and type columns' do
      insert_legacy(:custom_fields, name: 'Concentration', team_id: team.id, user_id: user.id)

      columns = service.get_custom_columns(team, repository)

      expect(columns.map(&:name)).to eq ['Concentration', 'Sample group', 'Sample type', 'Sample group color hex']
    end
  end

  describe '.create_text_cell and .create_list_cell' do
    let(:row) { create(:repository_row, repository: repository, created_by: user, last_modified_by: user) }
    let(:text_column) { create(:repository_column, repository: repository, data_type: :RepositoryTextValue) }
    let(:list_column) { create(:repository_column, repository: repository, data_type: :RepositoryListValue) }

    it 'inserts a text value and the cell that points to it' do
      # bug: app/services/tasks/samples_to_repository_migration_service.rb:186 uses Time#to_s(:db), which raises
      # ArgumentError on Rails 7.2
      pending 'bug: Time#to_s(:db) is not supported any more'
      service.create_text_cell(row.id, text_column.id, 'plain', user.id, user.id)

      expect(RepositoryCell.find_by(repository_row_id: row.id, repository_column_id: text_column.id)).to be_present
    end

    context 'with a clock supporting to_s(:db)' do
      include_context 'clock supporting to_s(:db)'

      it 'inserts a text value and the cell that points to it' do
        service.create_text_cell(row.id, text_column.id, "O'Brien", user.id, user.id)

        cell = RepositoryCell.find_by(repository_row_id: row.id, repository_column_id: text_column.id)
        expect(cell.value_type).to eq 'RepositoryTextValue'
        expect(cell.value.data).to eq "O'Brien"
        expect([cell.value.created_by_id, cell.value.last_modified_by_id]).to eq [user.id, user.id]
      end

      it 'inserts a list value for an existing list item and the cell that points to it' do
        item = create(:repository_list_item, repository_column: list_column, created_by: user,
                                             last_modified_by: user)

        service.create_list_cell(row.id, list_column.id, item.id, user.id, user.id)

        cell = RepositoryCell.find_by(repository_row_id: row.id, repository_column_id: list_column.id)
        expect(cell.value_type).to eq 'RepositoryListValue'
        expect(cell.value.repository_list_item_id).to eq item.id
      end
    end
  end

  describe '.update_annotation' do
    it 'rewrites ~sam~ smart annotation tags using the mapping and reports the change' do
      text = +"see ~sam~#{3.base62_encode}] and ~sam~#{4.base62_encode}]"

      expect(service.update_annotation(text, { 3 => 30 })).to be true
      expect(text).to eq "see ~rep_item~#{30.base62_encode}] and ~sam~#{4.base62_encode}]"
    end

    it 'returns false for nil and for text without a mapped sample tag' do
      untouched = +"~sam~#{9.base62_encode}] plain"

      expect(service.update_annotation(nil, {})).to be false
      expect(service.update_annotation(untouched, { 1 => 2 })).to be false
      expect(untouched).to eq "~sam~#{9.base62_encode}] plain"
    end
  end

  describe '.update_smart_annotations' do
    let(:project) { create(:project, team: team, created_by: user) }
    let(:tag) { "~sam~#{7.base62_encode}]" }
    let(:new_tag) { "~rep_item~#{70.base62_encode}]" }

    it 'updates annotations in project comments and experiment descriptions' do
      comment = create(:project_comment, project: project, user: user, message: "p #{tag}")
      experiment = create(:experiment, project: project, created_by: user)
      experiment.update_columns(description: "e #{tag}")

      service.update_smart_annotations(team, { 7 => 70 })

      expect(comment.reload.message).to eq "p #{new_tag}"
      expect(experiment.reload.description).to eq "e #{new_tag}"
    end

    it 'updates annotations in the tasks of the team' do
      experiment = create(:experiment, project: project, created_by: user)
      my_module = create(:my_module, experiment: experiment, created_by: user)
      my_module.update_columns(description: "t #{tag}")
      task_comment = create(:task_comment, my_module: my_module, user: user, message: "tc #{tag}")
      step = create(:step, protocol: my_module.protocol, user: user, description: "s #{tag}")

      # bug: app/services/tasks/samples_to_repository_migration_service.rb:253 eager loads Result#result_text,
      # an association that no longer exists, so any team with a task raises ActiveRecord::ConfigurationError
      pending 'bug: eager_load(:result_text) on Result'
      service.update_smart_annotations(team, { 7 => 70 })

      expect(my_module.reload.description).to eq "t #{new_tag}"
      expect(task_comment.reload.message).to eq "tc #{new_tag}"
      expect(step.reload.description).to eq "s #{new_tag}"
    end

    it 'updates annotations in the steps of team protocols and their comments' do
      # the callback reads protocol.my_module, which team protocols do not have
      allow_any_instance_of(StepComment).to receive(:fill_unseen_by)
      protocol = create(:protocol, :in_repository_published_original, team: team, added_by: user)
      step = create(:step, protocol: protocol, user: user, description: "ps #{tag}")
      step_comment = create(:step_comment, step: step, user: user, message: "psc #{tag}")

      service.update_smart_annotations(team, { 7 => 70 })

      expect(step.reload.description).to eq "ps #{new_tag}"
      expect(step_comment.reload.message).to eq "psc #{new_tag}"
    end

    it 'updates annotations in repository text cells' do
      row = create(:repository_row, repository: repository, created_by: user, last_modified_by: user)
      column = create(:repository_column, repository: repository, data_type: :RepositoryTextValue)
      text_value = create(:repository_text_value, data: "cell #{tag}", created_by: user, last_modified_by: user)
      create(:repository_cell, repository_row: row, repository_column: column, value: text_value)

      # bug: service line 271-274 uses includes(repository_cells: :repository_text_value), an instance dependent
      # association scope that cannot be eager loaded, so any team with a repository raises ArgumentError
      pending 'bug: includes of the instance dependent repository_text_value association'
      service.update_smart_annotations(team, { 7 => 70 })

      expect(text_value.reload.data).to eq "cell #{new_tag}"
    end
  end
end
