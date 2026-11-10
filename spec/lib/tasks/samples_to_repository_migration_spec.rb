# frozen_string_literal: true

require 'rails_helper'

describe 'samples_to_repository_migration:run' do
  include_context 'rake file loaded once', 'samples_to_repository_migration'
  include_context 'legacy samples tables'

  let(:service) { Tasks::SamplesToRepositoryMigrationService }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:team) { create(:team, created_by: user) }
  let(:project) { create(:project, team: team, created_by: user) }
  let(:experiment) { create(:experiment, project: project, created_by: user) }
  let(:my_module) { create(:my_module, experiment: experiment, created_by: user) }

  def run_task(*args)
    output = StringIO.new
    original = $stdout
    $stdout = output
    begin
      rake_task('samples_to_repository_migration:run').invoke(*args)
    ensure
      $stdout = original
    end
    output.string
  end

  def samples_repository(for_team)
    Repository.find_by(team: for_team, name: 'Samples')
  end

  # The legacy data set of a team: one sample with everything filled in and one sample with nothing but a name.
  def build_legacy_data
    type_id = insert_legacy(:sample_types, name: 'Plasma', team_id: team.id,
                                           created_by_id: other_user.id, last_modified_by_id: other_user.id)
    group_id = insert_legacy(:sample_groups, name: 'Group A', color: '#ff0000', team_id: team.id,
                                             created_by_id: other_user.id, last_modified_by_id: other_user.id)
    field_id = insert_legacy(:custom_fields, name: 'Concentration', team_id: team.id, user_id: user.id,
                                             created_at: Time.utc(2020, 1, 1), updated_at: Time.utc(2020, 1, 1))
    full = insert_legacy(:samples, name: 'Full sample', user_id: other_user.id, last_modified_by_id: user.id,
                                   team_id: team.id, sample_type_id: type_id, sample_group_id: group_id)
    insert_legacy(:sample_custom_fields, sample_id: full, custom_field_id: field_id, value: '5 mg')
    insert_legacy(:sample_my_modules, sample_id: full, my_module_id: my_module.id, assigned_by_id: other_user.id)
    bare = insert_legacy(:samples, name: 'Bare sample', team_id: team.id)
    insert_legacy(:sample_my_modules, sample_id: bare, my_module_id: my_module.id, assigned_by_id: nil)
    [full, bare]
  end

  describe 'with the unpatched Time#to_s(:db)' do
    it 'migrates the samples of a team' do
      build_legacy_data

      # bug: lib/tasks/samples_to_repository_migration.rake:14 passes the options hash positionally to
      # Team.find_each (ArgumentError on Ruby 3), and line 28 (and the service) call Time#to_s(:db), which raises
      # ArgumentError since Rails 7.1, so the task cannot run at all
      pending 'bug: Team.find_each(params) and Time#to_s(:db) raise ArgumentError'
      run_task

      expect(samples_repository(team).repository_rows.pluck(:name)).to match_array(['Full sample', 'Bare sample'])
    end
  end

  describe 'with a clock supporting to_s(:db)' do
    include_context 'clock supporting to_s(:db)'

    # Work around the positional options hash of Team.find_each in the rake file (bug, see the pending example above)
    before do
      allow(Team).to receive(:find_each).and_wrap_original { |original, options = {}, &block| original.call(**options, &block) }
    end

    context 'when the smart annotations update is skipped' do
      # The real Tasks::SamplesToRepositoryMigrationService.update_smart_annotations raises for every team that has
      # a repository (see the service spec); it is replaced here so the rest of the task can be tested.
      before { allow(service).to receive(:update_smart_annotations) }

      it 'creates the Samples repository with a row per sample and prints the progress' do
        full, bare = build_legacy_data

        output = run_task

        repository = samples_repository(team)
        expect(repository.created_by).to eq user
        rows = repository.repository_rows.index_by(&:name)
        expect(rows.keys).to match_array(['Full sample', 'Bare sample'])
        expect(rows['Full sample']).to have_attributes(created_by_id: other_user.id, last_modified_by_id: user.id)
        # missing authors fall back to the creator of the team
        expect(rows['Bare sample']).to have_attributes(created_by_id: user.id, last_modified_by_id: user.id)
        expect(output).to include("Processing Team id => [#{team.id}]")
        expect(service).to have_received(:update_smart_annotations)
          .with(team, { full => rows['Full sample'].id, bare => rows['Bare sample'].id })
      end

      it 'stores the sample type, group, group color and custom fields as cells' do
        build_legacy_data

        run_task

        repository = samples_repository(team)
        row = repository.repository_rows.find_by(name: 'Full sample')
        cells = row.repository_cells.includes(:repository_column).index_by { |c| c.repository_column.name }
        expect(cells.keys).to match_array(['Sample type', 'Sample group', 'Sample group color hex', 'Concentration'])
        expect(cells['Sample type'].value.repository_list_item.data).to eq 'Plasma'
        expect(cells['Sample group'].value.repository_list_item.data).to eq 'Group A'
        expect(cells['Sample group color hex'].value.data).to eq '#ff0000'
        expect(cells['Concentration'].value.data).to eq '5 mg'
        expect(repository.repository_rows.find_by(name: 'Bare sample').repository_cells).to be_empty
      end

      it 'assigns the rows to the tasks the samples were linked to' do
        build_legacy_data

        run_task

        repository = samples_repository(team)
        assignments = MyModuleRepositoryRow.where(my_module: my_module).index_by(&:repository_row_id)
        full_row = repository.repository_rows.find_by(name: 'Full sample')
        bare_row = repository.repository_rows.find_by(name: 'Bare sample')
        expect(assignments.keys).to match_array([full_row.id, bare_row.id])
        expect(assignments[full_row.id].assigned_by_id).to eq other_user.id
        # no assigner stored: the creator of the sample (here the team creator) is used
        expect(assignments[bare_row.id].assigned_by_id).to eq user.id
      end

      it 'turns the deprecated samples report elements into repository report elements' do
        report = create(:report, team: team, project: project, user: user)
        sample_element = create(:report_element, report: report, type_of: :my_module_samples)
        other_element = create(:report_element, report: report, type_of: :my_module, position: 2)

        run_task

        expect(sample_element.reload).to have_attributes(type_of: 'my_module_repository',
                                                         repository_id: samples_repository(team).id)
        expect(other_element.reload.type_of).to eq 'my_module'
      end

      it 'creates an empty Samples repository for a team without samples' do
        expect { run_task }.to change { samples_repository(team) }.from(nil)

        expect(samples_repository(team).repository_rows).to be_empty
        expect(samples_repository(team).repository_columns.pluck(:name))
          .to match_array(['Sample group', 'Sample group color hex', 'Sample type'])
      end

      it 'numbers the repository when the team already has one called Samples' do
        create(:repository, team: team, created_by: user, name: 'Samples')

        run_task

        expect(Repository.exists?(team: team, name: 'Samples (1)')).to be true
      end

      it 'only processes teams from the given last_id on' do
        skipped_team = create(:team, created_by: user)
        processed_team = create(:team, created_by: user)
        expect(processed_team.id).to be > skipped_team.id

        output = run_task(processed_team.id.to_s)

        expect(output).to include("Processing Team id => [#{processed_team.id}]")
        expect(output).not_to include("Processing Team id => [#{skipped_team.id}]")
        expect(samples_repository(skipped_team)).to be_nil
        expect(samples_repository(processed_team)).to be_present
      end

      it 'processes every team when no last_id is given' do
        other_team = create(:team, created_by: user)
        team

        run_task

        expect(samples_repository(team)).to be_present
        expect(samples_repository(other_team)).to be_present
      end

      it 'rolls the team back and re-raises when a cell cannot be created' do
        build_legacy_data
        allow(service).to receive(:create_text_cell).and_raise(StandardError, 'cell failure')

        expect { run_task }.to raise_error(StandardError, 'cell failure')
        expect(samples_repository(team)).to be_nil
      end
    end

    context 'when the smart annotations update is not skipped' do
      it 'migrates a team and updates its smart annotations' do
        build_legacy_data

        # bug: service line 253/274 (eager loading Result#result_text and an instance dependent association) make
        # update_smart_annotations raise for any team with a task or a repository, so the task never finishes
        pending 'bug: update_smart_annotations raises'
        run_task

        expect(samples_repository(team).repository_rows.count).to eq 2
      end
    end
  end
end
