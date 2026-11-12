# frozen_string_literal: true

require 'rails_helper'

describe GlobalActivitiesHelper, type: :helper do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) { create :my_module, experiment: experiment, created_by: user }
  let(:activity) do
    create :activity, type_of: 'create_project', team: team, owner: user, subject: project,
                      values: { 'message_items' => { 'user' => 'Jane', 'project' => project.name } }
  end

  before do
    without_partial_double_verification do
      allow(helper).to receive(:current_team).and_return(team)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can_read_repository?).and_return(true)
    end
  end

  def activity_with(type_of, items)
    create :activity, type_of: type_of, team: team, owner: user, subject: project,
                      values: { 'message_items' => items }
  end

  describe '#generate_activity_content' do
    it 'escapes plain string parameters before inserting them into the message' do
      record = activity_with('create_project', { 'project' => 'Acme <b>x</b> & Co' })

      content = helper.generate_activity_content(record, no_links: true)

      expect(content).to include 'created project Acme &lt;b&gt;x&lt;/b&gt; &amp; Co.'
      expect(content).not_to include '<b>x</b>'
    end

    it 'formats Time parameters with the full locale format' do
      timestamp = Time.zone.parse('2026-01-02 10:30').to_i
      record = activity_with('export_inventory_snapshot_items_assigned_to_task',
                             { 'user' => 'Jane', 'my_module' => 'Task A', 'repository_snapshot' => 'Snap',
                               'created_at' => { 'type' => 'Time', 'value' => timestamp } })

      content = helper.generate_activity_content(record)

      expect(content).to include "Snapshot of #{I18n.l(Time.zone.at(timestamp), format: :full)}"
    end

    it 'formats Date parameters with the full locale format' do
      record = activity_with('set_task_start_date',
                             { 'user' => 'Jane', 'my_module' => 'Task A',
                               'my_module_started_on' => { 'type' => 'Date', 'value' => '2026-01-02' } })

      content = helper.generate_activity_content(record)

      expect(content).to include I18n.l(Date.new(2026, 1, 2), format: :full)
    end

    it 'prefixes a non blank comment with the comments icon' do
      record = activity_with('inventory_item_stock_set',
                             { 'user' => 'Jane', 'repository_row' => 'Scale', 'new_amount' => '5', 'unit' => 'pcs',
                               'repository' => 'Inventory', 'comment' => 'Restocked' })

      content = helper.generate_activity_content(record)

      expect(content).to include 'sn-icon-comments'
      expect(content).to include 'Restocked'
    end

    it 'replaces a blank step position with the archived icon' do
      record = activity_with('create_step',
                             { 'user' => 'Jane', 'step_position' => '', 'step' => 'Step', 'my_module' => 'Task' })

      content = helper.generate_activity_content(record)

      expect(content).to include 'sn-icon-archived'
    end

    it 'renders names instead of links when no_links is true' do
      record = activity_with('create_project', { 'user' => 'Jane', 'project' => { 'type' => 'Project', 'id' => project.id } })

      content = helper.generate_activity_content(record, no_links: true)

      expect(content).to include "created project #{project.name}."
      expect(content).not_to include '<a '
    end

    it 'links to the object when no_links is false' do
      record = activity_with('create_project', { 'user' => 'Jane', 'project' => { 'type' => 'Project', 'id' => project.id } })

      content = helper.generate_activity_content(record)

      expect(content).to include %(href="#{experiments_path(project_id: project)}")
      expect(content).to include project.name
    end

    it 'auto links urls in the message unless no_custom_links is set' do
      record = activity_with('create_project', { 'user' => 'Jane', 'project' => 'https://example.com/x' })

      expect(helper.generate_activity_content(record)).to include 'href="https://example.com/x"'
      expect(helper.generate_activity_content(record, no_custom_links: true)).not_to include '<a '
    end

    it 'returns the content generation error message when an item cannot be resolved' do
      allow(Rails.logger).to receive(:error)
      record = activity_with('create_project', { 'user' => 'Jane', 'project' => { 'type' => 'NoSuchModel', 'id' => 1 } })

      expect(helper.generate_activity_content(record)).to eq(
        I18n.t('global_activities.index.content_generation_error', activity_id: record.id)
      )
      expect(Rails.logger).to have_received(:error).with(a_string_including('NoSuchModel')).at_least(:once)
    end
  end

  describe '#generate_link' do
    def item(type, record = nil, **extra)
      { 'type' => type, 'id' => record&.id, 'value' => record&.try(:name) || 'Value' }.merge(extra.stringify_keys)
    end

    it 'returns the stored value when the referenced record no longer exists' do
      expect(helper.generate_link({ 'type' => 'Project', 'id' => -1, 'value' => 'Gone' }, activity)).to eq 'Gone'
    end

    it 'returns a mention for a user' do
      expect(helper.generate_link(item('User', user), activity)).to eq "[@#{user.full_name}~#{user.id.base62_encode}]"
    end

    it 'returns the plain name of a tag' do
      tag = create :tag, team: team

      expect(helper.generate_link(item('Tag', tag), activity)).to eq tag.name
    end

    it 'links a team to the projects page of that team' do
      expect(helper.generate_link(item('Team', team), activity)).to include %(href="#{projects_path(team: team.id)}")
    end

    it 'links a readable repository and hides an unreadable one' do
      repository = create :repository, team: team, created_by: user
      expect(helper.generate_link(item('Repository', repository), activity))
        .to include %(href="#{repository_path(repository, team: team.id)}")

      without_partial_double_verification { allow(helper).to receive(:can_read_repository?).and_return(false) }
      expect(helper.generate_link(item('Repository', repository), activity)).to eq I18n.t('repositories.private')
    end

    it 'links a readable repository row and hides a row of an unreadable repository' do
      repository = create :repository, team: team, created_by: user
      row = create :repository_row, repository: repository

      expect(helper.generate_link(item('RepositoryRow', row), activity)).to include "row_id=#{row.id}"

      without_partial_double_verification { allow(helper).to receive(:can_read_repository?).and_return(false) }
      expect(helper.generate_link(item('RepositoryRow', row), activity)).to eq I18n.t('storage_locations.show.hidden')
    end

    it 'links an active project to its experiments and an archived project to the projects list' do
      expect(helper.generate_link(item('Project', project), activity))
        .to include %(href="#{experiments_path(project_id: project)}")

      project.update_columns(archived: true)
      expect(helper.generate_link(item('Project', project), activity)).to include %(href="#{projects_path}")
    end

    it 'links an active experiment to its modules and an archived experiment to the archive' do
      expect(helper.generate_link(item('Experiment', experiment), activity))
        .to include %(href="#{my_modules_experiment_path(experiment)}")

      experiment.update_columns(archived: true)
      expect(helper.generate_link(item('Experiment', experiment.reload), activity))
        .to include %(href="#{experiments_path(project_id: project, view_mode: :archived)}")
    end

    it 'returns the plain name of an experiment that is not navigable' do
      project.update_columns(archived: true)

      expect(helper.generate_link(item('Experiment', experiment), activity)).to eq experiment.name
    end

    it 'links an active task to its protocol and an archived task to the experiment archive' do
      expect(helper.generate_link(item('MyModule', my_module), activity))
        .to include %(href="#{protocols_my_module_path(my_module)}")

      my_module.update_columns(archived: true)
      expect(helper.generate_link(item('MyModule', my_module.reload), activity))
        .to include %(href="#{my_modules_experiment_path(experiment, view_mode: :archived)}")
    end

    it 'returns the plain name of a task that is not navigable' do
      project.update_columns(archived: true)

      expect(helper.generate_link(item('MyModule', my_module), activity)).to eq my_module.name
    end

    it 'links a protocol without task to the protocol page' do
      protocol = create :protocol, :in_public_repository, team: team

      expect(helper.generate_link(item('Protocol', protocol), activity)).to include %(href="#{protocol_path(protocol)}")
    end

    it 'links a result to its module results page' do
      result = create :result, my_module: my_module

      expect(helper.generate_link(item('Result', result), activity))
        .to include %(href="#{my_module_results_path(my_module, result_id: result.id)}")
    end

    it 'links a step of a repository protocol to the protocol page' do
      protocol = create :protocol, :in_repository_published_original, team: team, added_by: user,
                                                                      published_on: Time.zone.now
      step = create :step, protocol: protocol

      expect(helper.generate_link(item('Step', step), activity))
        .to include %(href="#{protocol_path(protocol, step_id: step.id)}")
    end

    # A deprecated in_repository_public protocol has no task, and the step branch then
    # calls navigable? on nil instead of falling back to the plain name.
    pending 'bug: step of a protocol without task crashes the activity link (nil my_module)' do
      protocol = create :protocol, :in_public_repository, team: team
      step = create :step, protocol: protocol

      expect { helper.generate_link(item('Step', step), activity) }.not_to raise_error
    end

    it 'links a step of a navigable task to the task protocol page' do
      step = create :step, protocol: my_module.protocol

      expect(helper.generate_link(item('Step', step), activity))
        .to include %(href="#{protocols_my_module_path(my_module, step_id: step.id)}")
    end

    it 'links a new project folder to the projects root' do
      expect(helper.generate_link({ 'type' => 'ProjectFolder' }, activity))
        .to include %(href="#{projects_path(team: team.id)}")
    end

    it 'links a form to the form page' do
      form = create :form, team: team, created_by: user

      expect(helper.generate_link(item('Form', form), activity)).to include %(href="#{form_path(form, team: team.id)}")
    end

    it 'returns the plain name for a record type without a dedicated link' do
      result_text = create :result_text, result: create(:result, my_module: my_module)

      expect(helper.generate_link(item('ResultText', result_text), activity)).to eq result_text.name
    end

    it 'links a user group to its settings page in the team' do
      user_group = create :user_group, team: team

      expect(helper.generate_link(item('UserGroup', user_group), activity))
        .to include %(href="#{users_settings_team_user_group_path(team, user_group)}")
    end

    it 'links a readable repository column to its repository and hides an unreadable one' do
      repository = create :repository, team: team, created_by: user
      column = create :repository_column, repository: repository

      expect(helper.generate_link(item('RepositoryColumn', column), activity))
        .to include %(href="#{repository_path(repository, team: team.id)}")

      without_partial_double_verification { allow(helper).to receive(:can_read_repository?).and_return(false) }
      expect(helper.generate_link(item('RepositoryColumn', column), activity))
        .to eq I18n.t('repositories.repository_column.private')
    end

    it 'returns the column name when its repository is missing' do
      repository = create :repository, team: team, created_by: user
      column = create :repository_column, repository: repository
      allow(column).to receive(:repository).and_return(nil)
      allow(RepositoryColumn).to receive(:find_by).with(id: column.id).and_return(column)

      expect(helper.generate_link(item('RepositoryColumn', column), activity)).to eq column.name
    end

    it 'links a protocol of a navigable task to the task protocol page' do
      expect(helper.generate_link(item('Protocol', my_module.protocol), activity))
        .to include %(href="#{protocols_my_module_path(my_module)}")
    end

    it 'returns the plain name of a protocol whose task is not navigable' do
      protocol = my_module.protocol
      protocol.update_columns(name: 'Protocol A')
      project.update_columns(archived: true)

      expect(helper.generate_link(item('Protocol', protocol), activity)).to eq 'Protocol A'
    end

    it 'returns the plain name of a step whose task is not navigable' do
      step = create :step, protocol: my_module.protocol
      project.update_columns(archived: true)

      expect(helper.generate_link(item('Step', step), activity)).to eq step.name
    end

    it 'links a report to the reports page previewing it as pdf by default' do
      report = create :report, team: team, project: project, user: user

      expect(helper.generate_link(item('Report', report), activity))
        .to include %(href="#{ERB::Util.html_escape(reports_path(team: team.id, preview_report_id: report.id, preview_type: :pdf))}")
    end

    it 'links a report to the reports page previewing it as docx for a docx generation activity' do
      report = create :report, team: team, project: project, user: user
      docx_activity = create :activity, type_of: 'generate_docx_report', team: team, owner: user, subject: project,
                                        values: { 'message_items' => {} }

      expect(helper.generate_link(item('Report', report), docx_activity))
        .to include %(href="#{ERB::Util.html_escape(reports_path(team: team.id, preview_report_id: report.id, preview_type: :docx))}")
    end

    it 'links an existing project folder to its folder page' do
      folder = create :project_folder, team: team

      expect(helper.generate_link(item('ProjectFolder', folder), activity))
        .to include %(href="#{project_folder_path(folder, team: team.id)}")
    end

    it 'links a container storage location to its page and a plain location to its parent listing' do
      container = StorageLocation.create!(team: team, created_by: user, name: 'Freezer', container: true)
      location = StorageLocation.create!(team: team, created_by: user, name: 'Shelf', container: false)

      expect(helper.generate_link(item('StorageLocation', container), activity))
        .to include %(href="#{storage_location_path(container, team: team.id)}")
      expect(helper.generate_link(item('StorageLocation', location), activity))
        .to include %(href="#{ERB::Util.html_escape(storage_locations_path(parent_id: location.id, team: team.id))}")
    end

    it 'links a result template to the result templates of its protocol' do
      result_template = create :result_template, protocol: create(:protocol, team: team)

      expect(helper.generate_link(item('ResultTemplate', result_template), activity))
        .to include %(href="#{protocol_result_templates_path(result_template.protocol)}")
    end
  end

  describe '#generate_name' do
    it 'returns the hidden label for a row of an unreadable repository' do
      repository = create :repository, team: team, created_by: user
      row = create :repository_row, repository: repository
      without_partial_double_verification { allow(helper).to receive(:can_read_repository?).and_return(false) }

      expect(helper.generate_name({ 'type' => 'RepositoryRow', 'id' => row.id })).to eq I18n.t('storage_locations.show.hidden')
    end

    it 'returns the root label for a new project folder and a new storage location' do
      expect(helper.generate_name({ 'type' => 'ProjectFolder' })).to eq I18n.t('projects.index.breadcrumbs_root')
      expect(helper.generate_name({ 'type' => 'StorageLocation' })).to eq I18n.t('storage_locations.index.breadcrumbs_root')
    end

    it 'returns the no name label for a record without name' do
      expect(helper.generate_name({ 'type' => 'Project' })).to eq I18n.t('global_activities.index.no_name')
    end

    it 'returns the stored value for a record that no longer exists' do
      expect(helper.generate_name({ 'type' => 'Project', 'id' => -1, 'value' => 'Old name' })).to eq 'Old name'
    end

    it 'uses the value_for attribute when given' do
      step = create :step, protocol: my_module.protocol
      step.update_columns(position: 3)

      expect(helper.generate_name({ 'type' => 'Step', 'id' => step.id, 'value_for' => 'position_plus_one' })).to eq 4
    end

    it 'returns the record name by default' do
      expect(helper.generate_name({ 'type' => 'Project', 'id' => project.id })).to eq project.name
    end
  end
end
