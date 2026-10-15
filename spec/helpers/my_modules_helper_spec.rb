# frozen_string_literal: true

require 'rails_helper'

describe MyModulesHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:protocol) { my_module.protocol }
  let(:now) { Time.zone.parse('2026-06-10 12:00') }

  before do
    without_partial_double_verification { allow(helper).to receive(:current_user).and_return(user) }
  end

  describe '#ordered_step_of' do
    it 'returns the protocol steps ordered by position' do
      first = create :step, protocol: protocol
      second = create :step, protocol: protocol
      first.update_columns(position: 5)
      second.update_columns(position: 1)

      expect(helper.ordered_step_of(my_module).map(&:id)).to eq [second.id, first.id]
    end
  end

  describe '#ordered_checklist_items' do
    it 'returns the checklist items ordered by position' do
      step = create :step, protocol: protocol
      checklist = create :checklist, step: step
      later = create :checklist_item, checklist: checklist
      earlier = create :checklist_item, checklist: checklist
      later.update_columns(position: 9)
      earlier.update_columns(position: 2)

      expect(helper.ordered_checklist_items(checklist).map(&:id)).to eq [earlier.id, later.id]
    end
  end

  describe 'step asset ordering' do
    let(:step) { create :step, protocol: protocol }
    # Created in this order, so created_at ascending is [first, second, third].
    let!(:first_asset) { create_asset_named('b-file.jpg') }
    let!(:second_asset) { create_asset_named('a-file.jpg') }
    let!(:third_asset) { create_asset_named('c-file.jpg') }

    def create_asset_named(filename)
      asset = create :asset, team: team
      asset.file.blob.update!(filename: filename)
      create :step_asset, step: step, asset: asset, team: team
      asset
    end

    def sort_assets_by(sort)
      step.current_view_state(user).update!(state: { 'assets' => { 'sort' => sort } })
    end

    describe '#ordered_assets' do
      it 'sorts newest first by default' do
        expect(helper.ordered_assets(step).map(&:id)).to eq [third_asset.id, second_asset.id, first_asset.id]
      end

      it 'sorts oldest first for the old sort' do
        sort_assets_by('old')

        expect(helper.ordered_assets(step).map(&:id)).to eq [first_asset.id, second_asset.id, third_asset.id]
      end

      it 'sorts by file name ascending for the atoz sort' do
        sort_assets_by('atoz')

        expect(helper.ordered_assets(step).map(&:id)).to eq [second_asset.id, first_asset.id, third_asset.id]
      end

      it 'sorts by file name descending for the ztoa sort' do
        sort_assets_by('ztoa')

        expect(helper.ordered_assets(step).map(&:id)).to eq [third_asset.id, first_asset.id, second_asset.id]
      end
    end

    describe '#az_ordered_assets_index' do
      it 'returns the position of the asset in case insensitive file name order' do
        expect(helper.az_ordered_assets_index(step, second_asset.id)).to eq 0
        expect(helper.az_ordered_assets_index(step, first_asset.id)).to eq 1
        expect(helper.az_ordered_assets_index(step, third_asset.id)).to eq 2
      end

      it 'returns 0 for an asset that is not part of the step' do
        expect(helper.az_ordered_assets_index(step, -1)).to eq 0
      end
    end
  end

  describe '#get_task_alert_color' do
    it 'returns red for an overdue task' do
      my_module.update_columns(due_date: 2.days.ago)

      expect(helper.get_task_alert_color(my_module.reload)).to eq ' alert-red'
    end

    it 'returns yellow for a task due within a day' do
      my_module.update_columns(due_date: 12.hours.from_now)

      expect(helper.get_task_alert_color(my_module.reload)).to eq ' alert-yellow'
    end

    it 'returns an empty string for a task without due date' do
      expect(helper.get_task_alert_color(my_module)).to eq ''
    end

    it 'returns an empty string for a completed or archived task' do
      my_module.update_columns(due_date: 2.days.ago, state: 'completed', completed_on: now)
      expect(helper.get_task_alert_color(my_module.reload)).to eq ''

      my_module.update_columns(state: 'uncompleted', completed_on: nil, archived: true)
      expect(helper.get_task_alert_color(my_module.reload)).to eq ''
    end
  end

  describe '#is_steps_page? and #is_results_page?' do
    it 'matches the steps and results actions' do
      allow(helper).to receive(:action_name).and_return('steps')
      expect(helper.is_steps_page?).to be true
      expect(helper.is_results_page?).to be false

      allow(helper).to receive(:action_name).and_return('results')
      expect(helper.is_steps_page?).to be false
      expect(helper.is_results_page?).to be true
    end
  end

  describe '#grouped_by_prj_exp' do
    it 'groups the tasks by their project and experiment' do
      other_experiment = create :experiment, project: project, created_by: user
      first_task = my_module
      second_task = create :my_module, experiment: experiment, created_by: user
      third_task = create :my_module, experiment: other_experiment, created_by: user
      other_experiment.update_columns(archived: true)
      tasks = MyModule.where(id: [first_task.id, second_task.id, third_task.id])

      groups = helper.grouped_by_prj_exp(tasks)

      expect(groups.size).to eq 2
      main_group = groups.find { |group| group[:experiment_name] == experiment.name }
      archived_group = groups.find { |group| group[:experiment_name] == other_experiment.name }

      expect(main_group[:project_name]).to eq project.name
      expect(main_group[:experiment_archived]).to be false
      expect(main_group[:tasks].map(&:id)).to match_array [first_task.id, second_task.id]
      expect(archived_group[:experiment_archived]).to be true
      expect(archived_group[:tasks].map(&:id)).to eq [third_task.id]
    end
  end

  describe 'assigned repository paths and labels' do
    let(:repository) { create :repository, team: team, created_by: user }
    let(:snapshot) { create :repository_snapshot, original_repository: repository, my_module: my_module }

    it 'uses the snapshot routes for repository snapshots and the live routes otherwise' do
      expect(helper.assigned_repository_full_view_table_path(my_module, snapshot))
        .to eq full_view_table_my_module_repository_snapshot_path(my_module, snapshot)
      expect(helper.assigned_repository_full_view_table_path(my_module, repository))
        .to eq full_view_table_my_module_repository_path(my_module, repository)
      expect(helper.assigned_repository_simple_view_index_path(my_module, snapshot))
        .to eq index_dt_my_module_repository_snapshot_path(my_module, snapshot)
      expect(helper.assigned_repository_simple_view_index_path(my_module, repository))
        .to eq index_dt_my_module_repository_path(my_module, repository)
    end

    it 'labels the footer with the snapshot date for snapshots and live otherwise' do
      expect(helper.assigned_repository_simple_view_footer_label(snapshot)).to eq(
        I18n.t('my_modules.repository.snapshots.simple_view.snapshot_bottom_label',
               date_time: I18n.l(snapshot.created_at, format: :full))
      )
      expect(helper.assigned_repository_simple_view_footer_label(repository)).to eq(
        I18n.t('my_modules.repository.snapshots.simple_view.live_bottom_label')
      )
    end

    it 'uses column 2 for the name in snapshot views and column 3 otherwise' do
      expect(helper.assigned_repository_simple_view_name_column_id(snapshot)).to eq 2
      expect(helper.assigned_repository_simple_view_name_column_id(repository)).to eq 3
    end
  end

  describe '#my_module_archived_on' do
    it 'returns the archive date of the task when the task is archived' do
      archived_at = Time.zone.parse('2026-01-02 10:00')
      my_module.update_columns(archived: true, archived_on: archived_at)

      expect(helper.my_module_archived_on(my_module.reload)).to eq archived_at
    end

    it 'returns the archive date of the experiment when only the experiment is archived' do
      archived_at = Time.zone.parse('2026-01-03 10:00')
      experiment.update_columns(archived: true, archived_on: archived_at)

      expect(helper.my_module_archived_on(my_module.reload)).to eq archived_at
    end

    it 'returns the archive date of the project when only the project is archived' do
      archived_at = Time.zone.parse('2026-01-04 10:00')
      project.update_columns(archived: true, archived_on: archived_at)

      expect(helper.my_module_archived_on(my_module.reload)).to eq archived_at
    end

    it 'returns nil when nothing in the hierarchy is archived' do
      expect(helper.my_module_archived_on(my_module)).to be_nil
    end
  end

  describe '#my_module_due_status' do
    it 'reports overdue tasks' do
      my_module.update_columns(due_date: now - 1.day)

      expect(helper.my_module_due_status(my_module.reload, now)).to eq I18n.t('my_modules.details.overdue')
    end

    it 'reports tasks due within a day as due soon' do
      my_module.update_columns(due_date: now + 6.hours)

      expect(helper.my_module_due_status(my_module.reload, now)).to eq I18n.t('my_modules.details.due_soon')
    end

    it 'returns an empty string for tasks due later' do
      my_module.update_columns(due_date: now + 5.days)

      expect(helper.my_module_due_status(my_module.reload, now)).to eq ''
    end

    it 'returns nil for archived or completed tasks' do
      my_module.update_columns(due_date: now - 1.day, archived: true)
      expect(helper.my_module_due_status(my_module.reload, now)).to be_nil

      my_module.update_columns(archived: false, due_date: now - 1.day, state: 'completed', completed_on: now)
      expect(helper.my_module_due_status(my_module.reload, now)).to be_nil
    end
  end

  describe '#serialize_assigned_my_module_value' do
    it 'returns team, project, experiment and task entries for an active hierarchy' do
      values = helper.serialize_assigned_my_module_value(my_module)

      expect(values).to eq [
        { type: 'team', value: team.name, url: projects_path(team: team.id), archived: false },
        { type: 'project', value: project.name,
          url: experiments_path(project_id: project, view_mode: 'active'), archived: false },
        { type: 'experiment', value: experiment.name,
          url: my_modules_experiment_path(experiment), archived: false },
        { type: 'my_module', value: my_module.name,
          url: protocols_my_module_path(my_module, view_mode: 'active'), archived: false }
      ]
    end

    it 'points archived entries to the archive views' do
      experiment.update_columns(archived: true, archived_on: now)
      project.update_columns(archived: true, archived_on: now)

      values = helper.serialize_assigned_my_module_value(my_module.reload)

      expect(values[1]).to include(archived: true, url: experiments_path(project_id: project, view_mode: 'archived'))
      expect(values[2]).to include(archived: true, url: module_archive_experiment_path(experiment))
      expect(values[3]).to include(archived: true, url: protocols_my_module_path(my_module, view_mode: 'archived'))
    end
  end
end
