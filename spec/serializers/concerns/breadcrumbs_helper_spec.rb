# frozen_string_literal: true

require 'rails_helper'

describe BreadcrumbsHelper do
  before(:all) { MyModuleStatusFlow.ensure_default }

  let(:host_class) do
    Class.new do
      include Rails.application.routes.url_helpers
      include BreadcrumbsHelper

      attr_reader :object

      def initialize(object = nil)
        @object = object
      end

      def crumbs(subject, anchor: nil)
        generate_breadcrumbs(subject, [], anchor: anchor)
      end
    end
  end
  let(:helper) { host_class.new }
  let(:routes) { Rails.application.routes.url_helpers }

  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: user, my_module_status: MyModuleStatus.first
  end
  let(:protocol) { my_module.protocol }
  let(:step) { create :step, protocol: protocol, user: user }

  def names(crumbs)
    crumbs.map { |c| c[:name] }
  end

  def team_crumb
    { name: team.name, code: nil, url: routes.projects_path(team: team.id) }
  end

  it 'returns an empty list for non existant records' do
    expect(helper.crumbs(NonExistantRecord.new('gone'))).to eq []
  end

  it 'returns the collected crumbs for unsupported subjects' do
    expect(helper.crumbs(user)).to eq []
  end

  it 'builds the full chain from team to task' do
    crumbs = helper.crumbs(my_module)

    expect(names(crumbs)).to eq [team.name, project.name, experiment.name, my_module.name]
    expect(crumbs.first).to eq team_crumb
    expect(crumbs.last).to eq(name: my_module.name, code: my_module.code,
                              url: routes.protocols_my_module_path(my_module))
    expect(crumbs[1][:url]).to eq routes.experiments_path(project_id: project.id)
    expect(crumbs[2][:url]).to eq routes.my_modules_experiment_path(experiment)
  end

  it 'passes the anchor to the first crumb only' do
    crumbs = helper.crumbs(experiment, anchor: 'top')
    expect(crumbs.last[:url]).to eq routes.my_modules_experiment_path(experiment, anchor: 'top')
    expect(crumbs[-2][:url]).to eq routes.experiments_path(project_id: project.id)
  end

  it 'routes projects through their folder' do
    folder = create :project_folder, team: team, name: 'Top folder'
    sub = create :project_folder, team: team, parent_folder: folder, name: 'Sub folder'
    project.update!(project_folder: sub)

    crumbs = helper.crumbs(project)
    expect(names(crumbs)).to eq [team.name, 'Top folder', 'Sub folder', project.name]
    expect(crumbs[2][:url]).to eq routes.project_folder_path(sub)
  end

  it 'skips crumbs without a name' do
    experiment.update_columns(name: '')
    expect(names(helper.crumbs(my_module))).to eq [team.name, project.name, my_module.name]
  end

  describe 'protocols' do
    it 'links task protocols to the task' do
      protocol.update!(name: 'Task protocol')
      crumbs = helper.crumbs(protocol)
      expect(names(crumbs).last(2)).to eq [my_module.name, 'Task protocol']
      expect(crumbs.last[:url]).to eq routes.protocols_my_module_path(my_module)
    end

    it 'links repository protocols to the protocol page' do
      repo_protocol = create :protocol, :in_repository_published_original, team: team, added_by: user
      crumbs = helper.crumbs(repo_protocol)
      expect(names(crumbs)).to eq [team.name, repo_protocol.name]
      expect(crumbs.last[:url]).to eq routes.protocol_path(repo_protocol)
    end

    it 'links steps of task protocols and archived steps' do
      crumbs = helper.crumbs(step)
      expect(crumbs.last[:url]).to eq routes.protocols_my_module_path(my_module, step_id: step.id)

      step.update_columns(archived: true)
      expect(helper.crumbs(step).last[:url])
        .to eq routes.archive_my_module_path(my_module, step_id: step.id, mode: :steps)
    end

    it 'links steps of repository protocols' do
      repo_protocol = create :protocol, :in_repository_published_original, team: team, added_by: user
      repo_step = create :step, protocol: repo_protocol, user: user
      expect(helper.crumbs(repo_step).last[:url]).to eq routes.protocol_path(repo_protocol, step_id: repo_step.id)
    end

    it 'resolves step elements to their step' do
      text = create :step_text, step: step
      checklist = create :checklist, step: step

      expect(helper.crumbs(text).last).to include(name: step.name,
                                                  url: routes.protocols_my_module_path(my_module, step_id: step.id,
                                                                                                  mode: :steps))
      expect(names(helper.crumbs(checklist)).last).to eq step.name
      step.update_columns(archived: true)
      expect(helper.crumbs(text.reload).last[:url])
        .to eq routes.archive_my_module_path(my_module, step_id: step.id, mode: :steps)
    end

    it 'resolves step tables and archived ones' do
      table = create(:step_table, step: step).table
      expect(helper.crumbs(table).last[:url])
        .to eq routes.protocols_my_module_path(my_module, step_id: step.id, mode: :steps)

      step.update_columns(archived: true)
      expect(helper.crumbs(table.reload).last[:url])
        .to eq routes.archive_my_module_path(my_module, step_id: step.id, mode: :steps)
    end

    it 'resolves form responses of steps' do
      response = create :form_response, parent: step
      crumbs = helper.crumbs(response)
      expect(crumbs.last[:name]).to eq step.name
      expect(crumbs.last[:url]).to eq routes.protocols_my_module_path(my_module, step_id: step.id, mode: :steps)
    end

    it 'resolves archived form responses' do
      response = create :form_response, parent: step
      response.update_columns(archived: true)
      expect(helper.crumbs(response.reload).last[:url])
        .to eq routes.archive_my_module_path(my_module, step_id: step.id, mode: :steps)
    end
  end

  describe 'results' do
    let(:result) { create :result, my_module: my_module, user: user }

    it 'links active and archived results' do
      expect(helper.crumbs(result).last[:url]).to eq routes.my_module_results_path(my_module, result_id: result.id)

      result.update_columns(archived: true, archived_on: Time.zone.now)
      expect(helper.crumbs(result.reload).last[:url])
        .to eq routes.archive_my_module_path(my_module, result_id: result.id, mode: :results)
    end

    it 'resolves result texts to their result' do
      text = create :result_text, result: result
      crumbs = helper.crumbs(text)
      expect(crumbs.last[:name]).to eq result.name
      expect(crumbs.last[:url]).to eq routes.my_module_results_path(my_module, result_id: result.id)
    end

    it 'resolves result tables for results' do
      table = create(:result_table, result: result).table
      expect(helper.crumbs(table).last[:url]).to eq routes.my_module_results_path(my_module, result_id: result.id)

      result.update_columns(archived: true)
      expect(helper.crumbs(table.reload).last[:url])
        .to eq routes.archive_my_module_path(my_module, result_id: result.id, mode: :results)
    end

    it 'resolves result templates, their texts and tables' do
      template = create :result_template, protocol: create(:protocol, :in_repository_published_original, team: team, added_by: user),
                                          user: user
      url = routes.protocol_result_templates_path(template.protocol, result_id: template.id)

      expect(helper.crumbs(template).last).to include(name: template.name, url: url)
      expect(helper.crumbs(create(:result_text, result: template)).last[:url]).to eq url
      expect(helper.crumbs(create(:result_table, result: template).table).last[:url]).to eq url
    end
  end

  it 'builds crumbs for repositories and rows' do
    repository = create :repository, team: team, created_by: user
    row = create :repository_row, repository: repository, created_by: user

    expect(helper.crumbs(repository).last[:url]).to eq routes.repository_path(repository)
    expect(names(helper.crumbs(row))).to eq [team.name, repository.name, row.name]
    expect(helper.crumbs(row).last[:url])
      .to eq routes.repository_path(repository, landing_page: true, row_id: row.id)

    row.update_columns(archived: true)
    expect(helper.crumbs(row.reload).last[:url])
      .to eq routes.repository_path(repository, landing_page: true, row_id: row.id, archived: true)
  end

  it 'builds a reports url, with preview params for notifications' do
    report = create :report, project: project, user: user, team: team
    expect(helper.crumbs(report).last[:url]).to eq routes.reports_path(team_id: team.id)

    notification = instance_double(Notification, params: { report_type: 'pdf' })
    allow(notification).to receive(:instance_of?).with(::Notification).and_return(true)
    crumbs = host_class.new(notification).crumbs(report)
    expect(crumbs.last[:url]).to eq routes.reports_path(preview_report_id: report.id, preview_type: 'pdf',
                                                         team_id: team.id)
  end

  it 'builds crumbs for label templates' do
    template = LabelTemplate.new(id: 77, team: team, name: 'Label tpl')
    crumbs = helper.crumbs(template)
    expect(names(crumbs)).to eq [team.name, 'Label tpl']
    expect(crumbs.last[:url]).to eq routes.label_template_path(template)
  end

  it 'builds crumbs for storage locations with and without a container' do
    location = StorageLocation.new(id: 88, team: team, name: 'Freezer', container: false)
    expect(helper.crumbs(location).last[:url])
      .to eq routes.storage_locations_path(parent_id: 88, team: team.id)

    box = StorageLocation.new(id: 89, team: team, name: 'Box', container: true)
    expect(helper.crumbs(box).last[:url]).to eq routes.storage_location_path(box, team: team.id)
  end

  it 'builds crumbs for forms' do
    form = create :form, team: team, created_by: user
    crumbs = helper.crumbs(form)
    expect(names(crumbs)).to eq [team.name, form.name]
    expect(crumbs.last[:url]).to eq routes.form_path(form, team: team.id)
  end

  it 'builds a single crumb for a team' do
    expect(helper.crumbs(team)).to eq [team_crumb]
  end
end
