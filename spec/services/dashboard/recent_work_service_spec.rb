# frozen_string_literal: true

require 'rails_helper'

describe Dashboard::RecentWorkService do
  let!(:user) { create :user }
  let!(:team) { create :team, created_by: user, skip_user_assignments: true }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:team_assignment) { create :user_assignment, user: user, assignable: team, user_role: owner_role }
  let!(:project) do
    create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id
  end
  let!(:experiment) { create :experiment, project: project, created_by: user }
  let!(:my_module) do
    create :my_module, experiment: experiment, created_by: user, my_module_status: MyModuleStatus.first
  end

  before(:all) { MyModuleStatusFlow.ensure_default }

  def log(subject, type_of, extra = {})
    Activity.create!({ owner: user, team: team, subject: subject, type_of: type_of,
                       project: project, message_items: {} }.merge(extra))
  end

  def call(mode = 'all')
    described_class.new(user, team, mode).call
  end

  describe '#call' do
    it 'returns task and project entries with urls and codes' do
      log(my_module, :create_module)
      log(project, :create_project)

      result = call
      by_group = result.index_by { |r| r[:group_id] }

      expect(by_group.keys).to contain_exactly("tsk#{my_module.id}", "pro#{project.id}")
      task = by_group["tsk#{my_module.id}"]
      expect(task[:subject_type]).to eq 'MyModule'
      expect(task[:name]).to eq my_module.name
      expect(task[:code]).to eq "#{MyModule::ID_PREFIX}#{my_module.id}"
      expect(task[:url]).to eq Rails.application.routes.url_helpers.protocols_my_module_path(my_module.id)
      expect(by_group["pro#{project.id}"][:url])
        .to eq Rails.application.routes.url_helpers.experiments_path(project_id: project.id)
      expect(task[:last_change]).to be_a(String)
    end

    it 'includes experiment entries' do
      # Experiment entries used to show up only when a project shared the experiment id, so keep the ids apart
      ActiveRecord::Base.connection.execute("SELECT setval('experiments_id_seq', 2000000)")
      new_experiment = create :experiment, project: project, created_by: user
      log(new_experiment, :create_experiment)
      expect(Project.where(id: new_experiment.id)).to be_empty

      by_group = call.index_by { |r| r[:group_id] }

      expect(by_group.keys).to eq ["exp#{new_experiment.id}"]
      entry = by_group["exp#{new_experiment.id}"]
      expect(entry[:subject_type]).to eq 'Experiment'
      expect(entry[:name]).to eq new_experiment.name
      expect(entry[:code]).to eq "#{Experiment::ID_PREFIX}#{new_experiment.id}"
      expect(entry[:url])
        .to eq Rails.application.routes.url_helpers.my_modules_experiment_path(new_experiment.id)
    end

    it 'orders by most recent change' do
      log(project, :create_project, created_at: 2.days.ago)
      log(my_module, :create_module, created_at: 1.day.ago)

      expect(call.map { |r| r[:group_id] }).to eq ["tsk#{my_module.id}", "pro#{project.id}"]
    end

    it 'filters by mode' do
      log(my_module, :create_module)
      expect(call('projects').size).to eq 1
      expect(call('protocols')).to be_empty
      expect(call('repositories')).to be_empty
      expect(call('reports')).to be_empty
    end

    it 'excludes archived objects' do
      log(my_module, :create_module)
      my_module.update_columns(archived: true)

      expect(call).to be_empty
    end

    it 'excludes blacklisted activity types and other users activities' do
      log(project, :export_protocol_in_repository)
      Activity.create!(owner: create(:user), team: team, subject: project, type_of: :create_project,
                       project: project, message_items: {})

      expect(call).to be_empty
    end

    it 'skips subjects the user cannot read activities for' do
      other = create :project, team: team, created_by: create(:user), visibility: :hidden
      log(other, :create_project, project: other)

      expect(call.map { |r| r[:group_id] }).not_to include("pro#{other.id}")
    end

    it 'skips experiments of projects the user cannot read activities for' do
      # Keep the experiment ids apart from the project ids, as in 'includes experiment entries'
      ActiveRecord::Base.connection.execute("SELECT setval('experiments_id_seq', 2000000)")
      visible_experiment = create :experiment, project: project, created_by: user
      hidden_project = create :project, team: team, created_by: create(:user), visibility: :hidden
      hidden_experiment = create :experiment, project: hidden_project
      expect(Project.where(id: [visible_experiment.id, hidden_experiment.id])).to be_empty
      log(visible_experiment, :create_experiment)
      log(hidden_experiment, :create_experiment, project: hidden_project)

      groups = call.pluck(:group_id)

      expect(groups).to include("exp#{visible_experiment.id}")
      expect(groups).not_to include("exp#{hidden_experiment.id}")
    end

    it 'includes team repositories' do
      repository = create :repository, team: team, created_by: user
      log(repository, :create_item_inventory)
      create_result = call('repositories')

      expect(create_result.map { |r| r[:group_id] }).to eq ["inv#{repository.id}"]
      expect(create_result.first[:url]).to eq Rails.application.routes.url_helpers.repository_path(repository.id)
    end

    it 'includes reports with edit url' do
      report = create :report, project: project, user: user, team: team
      log(report, :generate_pdf_report)
      res = call('reports')

      expect(res.map { |r| r[:group_id] }).to eq ["rpt#{report.id}"]
      expect(res.first[:url])
        .to eq Rails.application.routes.url_helpers.edit_project_report_path(project.id, report.id)
    end
  end
end
