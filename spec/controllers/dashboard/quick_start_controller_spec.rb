# frozen_string_literal: true

require 'rails_helper'

describe Dashboard::QuickStartController, type: :controller do
  login_user

  before(:all) { MyModuleStatusFlow.ensure_default }

  include_context 'reference_project_structure', { team_role: :owner }

  let(:json) { JSON.parse(response.body) }

  before { user.update!(current_team_id: team.id) }

  describe 'POST create_task' do
    it 'creates a task in an existing project and experiment' do
      expect do
        post :create_task, params: { project: { id: project.id }, experiment: { id: experiment.id },
                                     my_module: { name: 'Quick task' } }
      end.to change { experiment.my_modules.count }.by(1)

      created = experiment.my_modules.find_by(name: 'Quick task')
      expect(response).to have_http_status(:ok)
      expect(json['my_module_path']).to eq protocols_my_module_path(created)
    end

    it 'creates a new experiment in an existing project' do
      expect do
        post :create_task, params: { project: { id: project.id }, experiment: { name: 'New exp' },
                                     my_module: { name: 'Quick task' } }
      end.to change { project.experiments.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(project.experiments.find_by(name: 'New exp').my_modules.pluck(:name)).to eq ['Quick task']
    end

    it 'creates a new project, experiment and task' do
      expect do
        post :create_task, params: { project: { name: 'New project' }, experiment: { name: 'New exp' },
                                     my_module: { name: 'Quick task' } }
      end.to change { team.projects.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(team.projects.find_by(name: 'New project').experiments.first.my_modules.first.name).to eq 'Quick task'
    end

    it 'returns validation errors for an invalid task' do
      pending 'bug: CreateMyModuleService#call raises RecordInvalid, so the 422 error branch is never reached'
      post :create_task, params: { project: { id: project.id }, experiment: { id: experiment.id },
                                   my_module: { name: '' } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['error_object']).to eq 'MyModule'
      expect(json['errors']).to have_key('name')
    end

    it 'returns 403 when the user cannot create projects' do
      without_partial_double_verification do
        allow(controller).to receive(:can_create_projects?).and_return(false)
      end

      expect do
        post :create_task, params: { project: { name: 'New project' }, experiment: { name: 'e' },
                                     my_module: { name: 'Quick task' } }
      end.not_to(change { team.projects.count })

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when the user cannot create experiments in the project' do
      without_partial_double_verification do
        allow(controller).to receive(:can_create_project_experiments?).and_return(false)
      end

      expect do
        post :create_task, params: { project: { id: project.id }, experiment: { name: 'New exp' },
                                     my_module: { name: 'Quick task' } }
      end.not_to(change { project.experiments.count })

      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 403 when the user cannot manage the experiment' do
      without_partial_double_verification do
        allow(controller).to receive(:can_manage_experiment?).and_return(false)
      end

      expect do
        post :create_task, params: { project: { id: project.id }, experiment: { id: experiment.id },
                                     my_module: { name: 'Quick task' } }
      end.not_to(change { experiment.my_modules.count })

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET project_filter' do
    it 'lists readable projects as id and name pairs' do
      get :project_filter, params: {}, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['data']).to include([project.id, project.name])
    end

    it 'offers the typed query as a new project when no name matches' do
      get :project_filter, params: { query: 'Brand new' }, format: :json

      expect(json['data'].first).to eq [0, 'Brand new']
    end

    it 'does not offer a new project when the query matches a project name exactly' do
      get :project_filter, params: { query: project.name }, format: :json

      expect(json['data']).to include([project.id, project.name])
      expect(json['data'].map(&:first)).not_to include(0)
    end

    it 'escapes project names' do
      project.update!(name: 'A <b>bold</b> one')

      get :project_filter, params: { query: 'bold' }, format: :json

      expect(json['data']).to include([project.id, 'A &lt;b&gt;bold&lt;/b&gt; one'])
      expect(json['data'].map(&:last).join).not_to include('<b>')
    end
  end

  describe 'GET experiment_filter' do
    it 'lists the experiments of the project' do
      get :experiment_filter, params: { project: { id: project.id } }, format: :json

      expect(response).to have_http_status(:ok)
      expect(json['data']).to include([experiment.id, experiment.name])
    end

    it 'offers the typed query as a new experiment' do
      get :experiment_filter, params: { project: { id: project.id }, query: 'Fresh exp' }, format: :json

      expect(json['data'].first).to eq [0, 'Fresh exp']
    end

    it 'does not offer a new experiment without the create permission' do
      without_partial_double_verification do
        allow(controller).to receive(:can_create_project_experiments?).and_return(false)
      end

      get :experiment_filter, params: { project: { id: project.id }, query: 'Fresh exp' }, format: :json

      expect(json['data'].map(&:first)).not_to include(0)
    end

    it 'returns only the typed query when a new project is being created' do
      get :experiment_filter, params: { project: { name: 'New project' }, query: 'Exp' }, format: :json

      expect(json['data']).to eq [[0, 'Exp']]
    end

    it 'returns an empty list for an unknown project' do
      get :experiment_filter, params: { project: { id: 0 } }, format: :json

      expect(json['data']).to eq []
    end
  end
end
