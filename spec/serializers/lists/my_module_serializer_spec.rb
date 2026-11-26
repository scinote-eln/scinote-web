# frozen_string_literal: true

require 'rails_helper'

describe Lists::MyModuleSerializer do
  before(:all) { MyModuleStatusFlow.ensure_default }

  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:project) { create :project, team: team, created_by: user }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: user, my_module_status: MyModuleStatus.first,
                       name: 'Serialized task'
  end
  let(:routes) { Rails.application.routes.url_helpers }
  let(:viewer_role) { create :viewer_role }
  let(:result) { build_serializer.attributes }

  def build_serializer(record = my_module, **opts)
    acting_user = user
    described_class.new(record, scope: { user: acting_user }, scope_name: nil, user: acting_user, **opts).tap do |ser|
      ser.define_singleton_method(:current_user) { acting_user }
    end
  end

  def make_viewer
    UserAssignment.where(user: user, assignable: [team, project, experiment, my_module])
                  .update_all(user_role_id: viewer_role.id)
  end

  before do
    user.update!(current_team_id: team.id)
    allow(ReportTemplate).to receive(:analytical_reporting_enabled?).and_return(false)
  end

  it 'exposes the basic attributes' do
    expect(result).to include(
      name: 'Serialized task',
      code: my_module.code,
      experiment_id: experiment.id,
      project_id: project.id,
      team: team.name,
      archived: false,
      favorite: my_module.favorite,
      default_public_user_role_id: my_module.default_public_user_role_id
    )
    expect(result[:age]).to be_a(String)
    expect(result[:results]).to eq 0
    expect(result[:archived_on]).to be_nil
    expect(result[:analytical_report]).to be_nil
    expect(result[:tags_html]).to eq ''
  end

  it 'serializes the status' do
    status = MyModuleStatus.first
    expect(result[:status]).to eq(name: status.name, color: status.color, light_color: status.light_color?)
  end

  it 'builds task urls' do
    urls = result[:urls]
    expect(urls[:show]).to eq routes.protocols_my_module_path(my_module, view_mode: 'active')
    expect(urls[:results]).to eq routes.my_module_results_path(my_module)
    expect(urls[:update]).to eq routes.my_module_path(my_module)
    expect(urls[:users_list]).to eq routes.search_my_module_user_my_module_path(my_module, my_module_id: my_module.id)
    expect(urls[:user_group_members]).to eq routes.users_users_settings_team_user_groups_path(team_id: team.id)
    expect(urls).not_to have_key(:report)
  end

  it 'adds update urls and editable cells for an owner' do
    expect(result[:urls]).to include(:update_access, :update_due_date, :update_start_date)
    expect(result[:due_date_cell][:editable]).to be true
    expect(result[:start_date_cell][:editable]).to be true
    expect(result[:permissions]).to eq(manage_designated_users: true, create_comments: true, assign_tags: true)
  end

  it 'omits update urls and permissions for a viewer' do
    my_module
    make_viewer
    expect(result[:urls]).not_to include(:update_access, :update_due_date, :update_start_date)
    expect(result[:due_date_cell][:editable]).to be false
    expect(result[:start_date_cell][:editable]).to be false
    expect(result[:permissions]).to eq(manage_designated_users: false, create_comments: false, assign_tags: false)
  end

  describe 'due dates' do
    it 'is ok without a due date' do
      expect(result[:due_date]).to be_nil
      expect(result[:due_date_status]).to eq :ok
      expect(result[:due_date_cell][:icon]).to be_nil
    end

    it 'flags overdue tasks' do
      my_module.update!(due_date: 2.days.ago)
      expect(result[:due_date]).to eq I18n.l(my_module.due_date, format: :default)
      expect(result[:due_date_status]).to eq :overdue
      expect(result[:due_date_cell][:icon]).to include('text-sn-delete-red')
    end

    it 'flags tasks due within a day' do
      my_module.update!(due_date: 2.hours.from_now)
      expect(result[:due_date_status]).to eq :one_day_prior
      expect(result[:due_date_cell][:icon]).to include('text-sn-alert-brittlebush')
    end

    it 'is ok for future tasks and for completed overdue tasks' do
      my_module.update!(due_date: 10.days.from_now)
      expect(result[:due_date_status]).to eq :ok

      my_module.update_columns(due_date: 2.days.ago)
      allow(my_module).to receive(:completed?).and_return(true)
      expect(result[:due_date_status]).to eq :ok
      expect(result[:due_date_cell][:icon]).to be_nil
    end
  end

  it 'formats the start date' do
    my_module.update_columns(started_on: Time.zone.local(2026, 2, 3, 9))
    expect(result[:start_date_cell][:value]).to eq I18n.l(my_module.started_on, format: :default)
  end

  it 'lists designated users, tags and comment counts' do
    create :user_my_module, my_module: my_module, user: user, assigned_by: user
    tag = create :tag, team: team
    create :tagging, taggable: my_module, tag: tag
    create :task_comment, my_module: my_module, user: user

    designated = result[:designated_users]
    expect(designated.size).to eq 1
    expect(designated.first).to include(id: user.id, name: user.name)
    expect(result[:tags]).to eq [{ id: tag.id, name: tag.name, color: tag.color }]
    expect(result[:comments][:count]).to eq 1
    expect(result[:comments]).to have_key(:count_unseen)
  end

  it 'counts only active results for active tasks and all results for archived ones' do
    create :result, my_module: my_module, user: user
    create :result, my_module: my_module, user: user, archived: true, archived_on: Time.zone.now
    expect(result[:results]).to eq 1

    my_module.update_columns(archived: true, archived_on: Time.zone.now)
    serialized = build_serializer(my_module.reload).attributes
    expect(serialized[:archived]).to be true
    expect(serialized[:results]).to eq 2
    expect(serialized[:archived_on]).to eq I18n.l(my_module.archived_on, format: :full_date)
    expect(serialized[:urls][:show]).to eq routes.protocols_my_module_path(my_module, view_mode: 'archived')
  end

  it 'includes the analytical report when reporting is enabled' do
    report = instance_double(AnalyticalReport, name: 'Latest report', to_param: '7')
    allow(ReportTemplate).to receive(:analytical_reporting_enabled?).and_return(true)
    allow(my_module).to receive(:last_analytical_report).and_return(report)

    expect(result[:analytical_report]).to eq 'Latest report'
    expect(result[:urls][:report]).to eq routes.preview_my_module_my_module_report_path(my_module, report)
  end

  it 'renders legacy tag html through the controller when given' do
    controller = double
    allow(controller).to receive(:render_to_string).and_return('<div>tags</div>')
    ser = build_serializer(my_module, controller: controller)

    expect(ser.attributes[:tags_html]).to eq '<div>tags</div>'
    expect(controller).to have_received(:render_to_string)
      .with(partial: 'canvas/tags', locals: { my_module: my_module }, formats: :html)
  end
end
