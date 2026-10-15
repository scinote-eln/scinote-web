# frozen_string_literal: true

require 'rails_helper'

describe GlobalActivitiesController, type: :controller do
  login_user

  include_context 'reference_project_structure', { team_role: :owner }

  let!(:other_user) { create :user, full_name: 'Searchable Colleague' }
  let!(:other_assignment) { create_user_assignment(team, normal_user_role, other_user, user) }
  let!(:activity) do
    create :activity, team: team, owner: user, subject: project, project: project, type_of: :create_project
  end

  before { user.update!(current_team_id: team.id) }

  def json
    JSON.parse(response.body)
  end

  describe 'GET index' do
    it 'renders html with preloaded filters, teams and activity types' do
      get :index, params: { teams: [team.id] }
      expect(response).to have_http_status(:success)
      expect(assigns(:teams)).to include(team)
      expect(assigns(:activity_types)).to be_present
      expect(assigns(:filters)[:teams]).to eq [team.id.to_s]
      expect(assigns(:grouped_activities).values.flatten).to include(activity)
    end

    it 'groups activities by day and exposes the next page marker' do
      get :index
      expect(assigns(:grouped_activities).keys).to include(activity.created_at.to_date.to_s)
      expect(assigns(:next_page)).to be_nil
    end

    it 'passes subject labels into the filters' do
      get :index, params: { subject_labels: { Project: { project.id => project.name } } }
      expect(assigns(:filters)[:subject_labels]).to be_present
    end

    it 'returns json with the rendered list and the next page' do
      get :index, format: :json
      expect(response).to have_http_status(:success)
      expect(json).to include('activities_html', 'next_page')
    end

    it 'filters activities by type' do
      get :index, params: { types: [Activity.type_ofs[:create_report].to_s] }
      expect(assigns(:grouped_activities)).to be_empty
    end

    it 'only uses teams of the user' do
      foreign_team = create :team
      create :activity, team: foreign_team, subject: foreign_team, owner: create(:user)
      get :index, params: { teams: [foreign_team.id] }
      expect(assigns(:grouped_activities)).to be_empty
    end
  end

  describe 'GET team_filter' do
    it 'returns teams as options' do
      get :team_filter, params: { query: team.name[0, 4] }
      expect(response).to have_http_status(:success)
      expect(json).to include('value' => team.id, 'label' => team.name)
    end

    it 'filters teams by users' do
      get :team_filter, params: { users: [other_user.id] }
      expect(json.pluck('value')).to include(team.id)
    end

    it 'filters teams by subjects' do
      get :team_filter, params: { subjects: { Project: [project.id] } }
      expect(json.pluck('value')).to include(team.id)
    end
  end

  describe 'GET user_filter' do
    it 'returns users matching the query' do
      get :user_filter, params: { query: 'Searchable' }
      expect(json).to include('value' => other_user.id, 'label' => 'Searchable Colleague')
    end

    it 'limits users to a module when my_module_id is given' do
      get :user_filter, params: { my_module_id: my_module.id }
      expect(response).to have_http_status(:success)
      expect(json).to be_an(Array)
    end
  end

  describe 'object filters' do
    let!(:tagged_report) { create :report, project: project, user: user, team: team, name: 'Findable report' }
    let!(:protocol) do
      create :protocol, :in_repository_published_original, team: team, added_by: user, name: 'Findable protocol'
    end
    let!(:repository) { create :repository, team: team, created_by: user, name: 'Findable inventory' }
    let!(:repository_row) do
      create :repository_row, repository: repository, created_by: user, last_modified_by: user, name: 'Findable row'
    end

    before do
      create_user_assignment(repository, owner_role, user)
      project.update!(name: 'Findable project')
      experiment.update!(name: 'Findable experiment')
      my_module.update!(name: 'Findable task')
    end

    {
      project_filter: ['Findable project', {}],
      experiment_filter: ['Findable experiment', { subjects: { Project: [-1] } }],
      my_module_filter: ['Findable task', { subjects: { Experiment: [-1] } }],
      inventory_filter: ['Findable inventory', {}],
      protocol_filter: ['Findable protocol', {}],
      report_filter: ['Findable report', {}]
    }.each do |action, (name, extra)|
      it "#{action} finds objects by name" do
        extra = { subjects: { Project: [project.id], Experiment: [experiment.id] } } if extra.present?
        get action, params: { query: 'Findable' }.merge(extra)
        expect(response).to have_http_status(:success)
        expect(json.pluck('label')).to include(name)
      end
    end

    it 'inventory_item_filter finds rows' do
      get :inventory_item_filter, params: { query: 'Findable', subjects: { RepositoryBase: [repository.id] } }
      expect(json.pluck('label')).to include('Findable row')
    end

    # bug: the dependent filters index into params[:subjects] without a nil check
    it 'raises for dependent filters when the subjects param is missing' do
      expect { get :experiment_filter, params: { query: 'Findable' } }.to raise_error(NoMethodError)
      expect { get :my_module_filter, params: { query: 'Findable' } }.to raise_error(NoMethodError)
      expect { get :inventory_item_filter, params: { query: 'Findable' } }.to raise_error(NoMethodError)
    end

    it 'does not return objects of teams the user cannot access' do
      other_project = create :project, name: 'Findable foreign'
      get :project_filter, params: { query: 'Findable' }
      expect(json.pluck('value')).not_to include(other_project.id)
    end

    it 'limits experiments to the selected projects' do
      other_project = create :project, team: team, created_by: user, name: 'Other P'
      create_user_assignment(other_project, owner_role, user)
      other_experiment = create :experiment, project: other_project, created_by: user, name: 'Findable other exp'
      get :experiment_filter, params: { query: 'Findable', subjects: { Project: [project.id] } }
      expect(json.pluck('value')).to include(experiment.id)
      expect(json.pluck('value')).not_to include(other_experiment.id)
    end

    it 'limits tasks to the selected experiments' do
      other_experiment = create :experiment, project: project, created_by: user, name: 'Another exp'
      other_task = create :my_module, experiment: other_experiment, created_by: user, name: 'Findable other task',
                                      my_module_status: MyModuleStatus.first
      get :my_module_filter, params: { query: 'Findable', subjects: { Experiment: [experiment.id] } }
      expect(json.pluck('value')).to include(my_module.id)
      expect(json.pluck('value')).not_to include(other_task.id)
    end

    it 'limits inventory items to the selected inventories' do
      get :inventory_item_filter, params: { query: 'Findable', subjects: { RepositoryBase: [-1] } }
      expect(json).to eq('data' => [])
    end

    it 'limits objects to selected teams' do
      get :project_filter, params: { query: 'Findable', teams: [team.id] }
      expect(json.pluck('value')).to include(project.id)
    end

    it 'limits objects by users' do
      get :project_filter, params: { query: 'Findable', users: [user.id] }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST save_activity_filter' do
    let(:params) do
      { name: 'My filter', filter: { from_date: '', to_date: '', types: ['1'], users: [user.id.to_s],
                                     teams: [team.id.to_s] } }
    end

    around do |example|
      original = Rails.application.config.x.webhooks_enabled
      Rails.application.config.x.webhooks_enabled = true
      example.run
      Rails.application.config.x.webhooks_enabled = original
    end

    it 'saves the filter' do
      expect { post :save_activity_filter, params: params, format: :json }.to change(ActivityFilter, :count).by(1)
      expect(response).to have_http_status(:success)
      expect(ActivityFilter.last.filter['types']).to eq ['1']
      expect(json['message']).to eq I18n.t('global_activities.index.activity_filter_saved')
    end

    it 'returns validation errors' do
      expect { post :save_activity_filter, params: params.merge(name: ''), format: :json }
        .not_to change(ActivityFilter, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to be_present
    end

    it 'is forbidden when activity filters are disabled' do
      Rails.application.config.x.webhooks_enabled = false
      expect { post :save_activity_filter, params: params, format: :json }.not_to change(ActivityFilter, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
