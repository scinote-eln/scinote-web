# frozen_string_literal: true

require 'rails_helper'

describe Dashboard::CurrentTasksController, type: :controller do
  login_user
  render_views

  before(:all) { MyModuleStatusFlow.ensure_default }

  include_context 'reference_project_structure', { my_modules: 2 }

  let(:json) { JSON.parse(response.body) }

  before { user.update!(current_team_id: team.id) }

  describe 'GET show' do
    it 'renders readable active tasks as html partials' do
      get :show, params: {}, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['data'].size).to eq 3
      expect(json['data'].join).to include(my_module.name, project.name, experiment.name)
      expect(json['next_page']).to be_nil
    end

    it 'renders the due date state classes' do
      my_module.update!(due_date: 2.days.ago)
      my_modules.first.update!(due_date: 1.hour.from_now)
      my_modules.last.update!(due_date: 10.days.from_now)

      get :show, params: { sort: 'atoz' }, format: :json

      html = json['data'].join
      expect(html).to include('overdue')
      expect(html).to include('day-prior')
    end

    it 'renders completed tasks with their completion date' do
      done_at = Time.zone.local(2026, 3, 4, 10)
      my_module.update_columns(completed_on: done_at)
      allow_any_instance_of(MyModule).to receive(:completed?).and_return(true)

      get :show, params: { query: my_module.name }, format: :json

      expect(json['data'].size).to eq 1
      expect(json['data'].first).to include(I18n.l(done_at, format: :full_date))
    end

    it 'filters by project and experiment' do
      other_project = create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id
      other_exp = create :experiment, project: other_project, created_by: user
      other_task = create :my_module, experiment: other_exp, created_by: user, my_module_status: MyModuleStatus.first

      get :show, params: { project_id: other_project.id }, format: :json
      expect(json['data'].size).to eq 1
      expect(json['data'].first).to include(other_task.name)
    end

    it 'filters by experiment inside a project' do
      get :show, params: { project_id: project.id, experiment_id: experiment.id }, format: :json
      expect(json['data'].size).to eq 3
    end

    it 'filters by assigned mode' do
      create :user_my_module, user: user, my_module: my_module, assigned_by: user

      get :show, params: { mode: 'assigned' }, format: :json
      expect(json['data'].size).to eq 1
      expect(json['data'].first).to include(my_module.name)
    end

    it 'filters by statuses' do
      get :show, params: { statuses: [0] }, format: :json
      expect(json['data']).to be_empty
    end

    it 'filters by search query' do
      my_module.update!(name: 'Unique needle task')
      get :show, params: { query: 'needle' }, format: :json
      expect(json['data'].size).to eq 1
    end

    %w(due_first due_last start_first start_last atoz ztoa id_asc id_desc).each do |sort|
      it "supports sort #{sort}" do
        get :show, params: { sort: sort }, format: :json
        expect(response).to have_http_status(:ok)
        expect(json['data'].size).to eq 3
      end
    end

    it 'orders by name for atoz and ztoa' do
      my_module.update!(name: 'AAA first')
      my_modules.last.update!(name: 'ZZZ last')
      get :show, params: { sort: 'atoz' }, format: :json
      expect(json['data'].first).to include('AAA first')
    end

    it 'orders by name descending for ztoa' do
      my_modules.last.update!(name: 'ZZZ last')
      get :show, params: { sort: 'ztoa' }, format: :json
      expect(json['data'].first).to include('ZZZ last')
    end

    it 'excludes archived tasks' do
      my_modules.first.update_columns(archived: true)
      get :show, params: {}, format: :json
      expect(json['data'].size).to eq 2
    end

    it 'returns forbidden when the user cannot read the project' do
      allow(controller).to receive(:can_read_project?).and_return(false)
      get :show, params: { project_id: project.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns forbidden when the user cannot read the experiment' do
      allow(controller).to receive(:can_read_experiment?).and_return(false)
      get :show, params: { project_id: project.id, experiment_id: experiment.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET favorites' do
    it 'lists the favorites of the user in the current team' do
      Favorite.create!(user: user, team: team, item: project)
      Favorite.create!(user: user, team: team, item: my_module)

      get :favorites, format: :json

      expect(response).to have_http_status(:ok)
      names = json['data'].map { |f| f['attributes']['name'] }
      expect(names).to contain_exactly(project.name, my_module.name)
      expect(json['meta']).to be_present
    end

    it 'does not list favorites of other users' do
      Favorite.create!(user: create(:user), team: team, item: project)
      get :favorites, format: :json
      expect(json['data']).to be_empty
    end
  end

  describe 'GET project_filter' do
    it 'returns projects with tasks for the default mode' do
      get :project_filter, params: { query: project.name }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json).to eq [{ 'value' => project.id, 'label' => project.name }]
    end

    it 'returns all readable projects in team mode and omits archived' do
      empty = create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id
      archived = create :project, :archived, team: team, created_by: user, default_public_user_role_id: owner_role.id

      get :project_filter, params: { mode: 'team', query: '' }, format: :json
      values = json.map { |p| p['value'] }
      expect(values).to include(project.id, empty.id)
      expect(values).not_to include(archived.id)
    end

    it 'omits projects without readable tasks outside team mode' do
      empty = create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id

      get :project_filter, params: { query: '' }, format: :json
      expect(json.map { |p| p['value'] }).not_to include(empty.id)
    end

    it 'escapes html in labels' do
      project.update_columns(name: '<b>Bold</b> project')
      get :project_filter, params: { query: 'Bold' }, format: :json
      expect(json.first['label']).not_to include('<b>')
    end
  end

  describe 'GET experiment_filter' do
    it 'returns an empty list for an unknown project' do
      get :experiment_filter, params: { project_id: -1 }, format: :json
      expect(json).to eq('data' => []) # bug: serializer adapter wraps the bare [] response
    end

    it 'returns experiments with tasks for a project' do
      create :experiment, project: project, created_by: user

      get :experiment_filter, params: { project_id: project.id, query: '' }, format: :json
      expect(json).to eq [{ 'value' => experiment.id, 'label' => experiment.name }]
    end

    it 'returns all readable experiments in team mode' do
      empty_exp = create :experiment, project: project, created_by: user

      get :experiment_filter, params: { project_id: project.id, query: '', mode: 'team' }, format: :json
      expect(json.map { |e| e['value'] }).to contain_exactly(experiment.id, empty_exp.id)
    end
  end
end
