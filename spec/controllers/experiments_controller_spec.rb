# frozen_string_literal: true

require 'rails_helper'

describe ExperimentsController, type: :controller do
  login_user
  include_context 'reference_project_structure'

  let(:archived_experiment) do
        create :experiment,
               archived: true,
               archived_by: (create :user),
               archived_on: Time.zone.now,
               project: project,
               created_by: project.created_by
      end


  describe 'GET index' do
    before(:all) do
      MyModuleStatusFlow.ensure_default
    end

    let(:action) { get :index, params: { project_id: experiment.project.id, page: 1, per_page: 20 }, format: :json }
    let(:action_html) { get :index, params: { project_id: experiment.project.id, page: 1, per_page: 20 }, format: :html }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(1)
      expect(parsed_response['data'].first['id']).to eq(experiment.id.to_s)
    end

    it 'correct HTML format' do
      action_html  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'GET show' do
    let(:action) { get :show, params: { project_id: experiment.project.id, id: experiment.id }, format: :json }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data']['id']).to eq(experiment.id.to_s)
    end
  end

  describe 'GET assigned_users' do
    let(:action) { get :assigned_users, params: { id: experiment.id }, format: :json }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(1)
      expect(parsed_response['data'].first['id']).to eq(user.id.to_s)
    end
  end


  describe 'GET canvas' do
    let(:action) { get :canvas, params: { id: experiment.id } }
    it 'successful call' do
      action  
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET my_modules' do
    let(:action) { get :my_modules, params: { id: experiment.id }, format: :json }

    it 'correct JSON format' do
      action  
      expect(response).to have_http_status(:found)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'PUT view_type' do
    shared_examples 'redirects with HTML response' do
      it 'redirects with 302 and HTML' do
        action
        expect(response).to have_http_status(:found)
        expect(response.media_type).to eq('text/html')
      end
    end

    context 'archived mode' do
      let(:action) { put :view_type, params: { id: experiment.id, experiment: { view_type: view_type }, view_mode: 'archived' }, format: :json }

      context 'canvas view' do
        let(:view_type) { 'canvas' }
        include_examples 'redirects with HTML response'
      end

      context 'table view' do
        let(:view_type) { 'table' }
        include_examples 'redirects with HTML response'
      end
    end

    context 'active mode' do
      let(:action) { put :view_type, params: { id: experiment.id, experiment: { view_type: view_type } }, format: :json }

      context 'canvas view' do
        let(:view_type) { 'canvas' }
        include_examples 'redirects with HTML response'
      end

      context 'table view' do
        let(:view_type) { 'table' }
        include_examples 'redirects with HTML response'
      end
    end
  end

  describe 'GET module_archive' do
    let(:action) { get :module_archive, params: { id: experiment.id } }
    it 'successful call' do
      action  
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'text/html'
    end
  end

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { project_id: project.id,
        experiment: { name: 'test experiment A1',
                      description: 'test description one' } }
    end

    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :create_experiment))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params }

    context 'when editing experiment' do
      let(:params) do
        {
          id: experiment.id,
          experiment: { name: 'new_title', description: 'new description' }
        }
      end

      it 'calls create activity for editing experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :edit_experiment)))
        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

     context 'when renaming experiment' do
      let(:params) do
        {
          id: experiment.id,
          experiment: { name: 'new_title' }
        }
      end

      it 'calls create activity for editing experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
                .with(hash_including(activity_type: :rename_experiment)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when archiving experiment' do
      let(:params) {{ id: archived_experiment.id, experiment: { archived: false }}}

      it 'calls create activity for unarchiving experiment' do
        expect(Activities::CreateActivityService)
          .to(receive(:call)
            .with(hash_including(activity_type: :restore_experiment)))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end
  end

  describe 'GET archive' do
    let(:action) { get :archive, params: params, format: :json }
    let(:params) do
      { id: experiment.id,
        experiment: { archived: false } }
    end
    it 'calls create activity service' do
      expect(Activities::CreateActivityService).to receive(:call)
        .with(hash_including(activity_type: :archive_experiment))

      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'POST archive_group' do
    let(:action) { post :archive_group, params: { project_id: experiment.project.id, experiment_ids: experiment_list } }

    context 'when valid experiments' do
      let(:experiment_list) { [experiment.id] }
      it 'archive experiments' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :archive_experiment))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when not valid experiments' do
      let(:experiment_list) { [-1] }
      it 'archive experiments' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end

  describe 'POST restore_group' do
    let(:action) { post :restore_group, params: { project_id: archived_experiment.project.id, experiment_ids: experiment_list } }

    context 'when valid experiments' do
      let(:experiment_list) { [archived_experiment.id] }
      it 'restore experiments' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end

      it 'calls create activity service' do
        expect(Activities::CreateActivityService).to receive(:call)
          .with(hash_including(activity_type: :restore_experiment))

        action
      end

      it 'adds activity in DB' do
        expect { action }
          .to(change { Activity.count })
      end
    end

    context 'when not valid experiments' do
      let(:experiment_list) { [-1] }
      it 'restore experiments' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq 'application/json'
      end
    end
  end

  describe 'GET projects_to_clone' do
    let(:action) { get :projects_to_clone, params: { id: experiment.id, query: ''}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(experiment.project.team.projects.active.count)
    end
  end

  describe 'GET projects_to_move' do
    let(:action) { get :projects_to_move, params: { id: experiment.id, query: ''}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(experiment.project.team.projects.active.count - 1)
    end
  end

  describe 'GET experiments_to_move' do
    let(:action) { get :experiments_to_move, params: { project_id: experiment.project.id, query: ''}, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      parsed_response = JSON.parse(response.body)
      expect(parsed_response['data'].count).to eq(experiment.project.experiments.active.count)
    end
  end

  describe 'POST clone' do
    let!(:project_second) { create(:project, team: team, created_by: user) }
    let(:action) { post :clone, params: { project_id: experiment.project.id, id: experiment.id, experiment: { project_id: project_second.id }} }

    it 'creates a clone' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end
  end

  describe 'POST move' do
    let(:project_second) { create(:project, team: team, created_by: user) }
    let(:action) { post :move, params: params }

    context 'when moving experiments to another project' do
      let(:params) {{ project_id: project_second.id, ids: [experiment.id] }}

      it 'returns success JSON' do
        action
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq 'application/json'
      end
    end

    context 'when moving experiments to the same project (invalid)' do
      let(:params) {{ project_id: experiment.project.id, ids: [experiment.id] }}

      it 'returns unprocessable entity' do
        action
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'POST move_modules' do
    let!(:experiment_second) { create(:experiment, project_id: project.id, created_by: user) }
    let(:action) { post :move_modules, params: { id: experiment.id, to_experiment_id: experiment_second.id, my_module_ids: [my_module.id] }}

    it 'move tasks succesfully' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end
  end

  describe 'POST archive_my_modules' do
    let!(:experiment_second) { create(:experiment, project_id: project.id, created_by: user) }
    let(:action) { post :archive_my_modules, params: { id: experiment.id, my_modules: [my_module.id] }}

    it 'archive tasks succesfully' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end
  end

  describe 'GET inventory_assigning_experiment_filter' do
    let(:action) { get :inventory_assigning_experiment_filter, params: { project_id: project.id }, format: :json }

    it 'correct JSON format' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(response.body).not_to be_empty
    end
  end

   describe 'POST batch_clone_my_modules' do
    let(:action) { post :batch_clone_my_modules, params: { id: experiment.id, my_module_ids: [my_module.id] }}

    it 'move tasks succesfully' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      expect(response.body).not_to be_empty
    end
  end

  describe 'POST favorite' do
    let(:action) { post :favorite, params: { id: experiment.id } }

    it 'creates a favorite' do
      expect(user.favorites.exists?(item: experiment )).to eq(false)
      action
      expect(user.favorites.exists?(item: experiment )).to eq(true)
    end
  end

  describe 'POST unfavorite' do
    let(:action) { post :unfavorite, params: { id: experiment.id } }

    it 'removes a favorite' do
      Favorite.create!(user: user, item: experiment, team: experiment.team)
      action
      expect(user.favorites.exists?(item: experiment )).to eq(false)
    end
  end
end
