# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::BaseController, type: :controller do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let(:project) do
    create :project, team: team, created_by: user, default_public_user_role_id: owner_role.id
  end
  let!(:project_assignment) { create_user_assignment(project, owner_role, user) }
  let(:experiment) { create :experiment, project: project, created_by: user }
  let(:my_module) do
    create :my_module, experiment: experiment, created_by: user, my_module_status: MyModuleStatus.first
  end
  let(:protocol) { my_module.protocol }
  let(:step) { create :step, protocol: protocol, user: user }

  def json
    JSON.parse(response.body)
  end

  def error_title
    json['errors'].first['title']
  end

  controller(Api::V1::BaseController) do
    def raise_error
      error = params[:kind].constantize
      case params[:kind]
      when 'Api::V1::BaseController::PermissionError'
        raise error.new(Project, :read)
      when 'ActiveRecord::RecordNotFound'
        raise error.new('missing', Project, 'id', 42)
      when 'ActiveRecord::RecordInvalid'
        raise error.new(Project.new)
      when 'ActionController::ParameterMissing'
        raise error.new(:thing)
      when 'JWT::DecodeError', 'JWT::InvalidPayload', 'JWT::VerificationError', 'JWT::ExpiredSignature'
        raise error, 'jwt problem'
      else
        raise error, 'boom'
      end
    end

    def chain
      load_team
      load_inventory if params[:inventory_id]
      load_inventory_column if params[:column_id]
      load_inventory_item if params[:item_id]
      load_project if params[:project_id]
      load_experiment if params[:experiment_id]
      load_task if params[:task_id]
      load_protocol if params[:protocol_id]
      load_step if params[:step_id]
      load_table if params[:table_id]
      load_checklist if params[:checklist_id]
      load_step_text if params[:step_text_id]
      load_checklist_item if params[:checklist_item_id]
      load_workflow if params[:workflow_id]
      render json: {
        team: @team&.id, inventory: @inventory&.id, column: @inventory_column&.id, item: @inventory_item&.id,
        project: @project&.id, experiment: @experiment&.id, task: @task&.id, protocol: @protocol&.id,
        step: @step&.id, table: @table&.id, checklist: @checklist&.id, step_text: @step_text&.id,
        checklist_item: @checklist_item&.id, workflow: @workflow&.id
      }
    end

    def filters
      records = Project.where(team_id: params[:team_id])
      records = name_filter(records)
      records = archived_filter(records, default_to_active: params[:default_to_active] == 'true')
      records = timestamps_filter(records)
      render json: { ids: records.order(:id).pluck(:id) }
    end

    def metadata
      render json: { ids: metadata_filter(MyModule.all).order(:id).pluck(:id) }
    end

    def includes
      render json: { includes: include_params }
    end

    def permitted_includes
      %w(a b)
    end
  end

  before do
    routes.draw do
      get 'raise_error' => 'api/v1/base#raise_error', as: :raise_error
      get 'chain' => 'api/v1/base#chain'
      get 'filters' => 'api/v1/base#filters'
      get 'metadata' => 'api/v1/base#metadata'
      get 'includes' => 'api/v1/base#includes'
      get 'index' => 'api/v1/base#index'
      get 'show' => 'api/v1/base#show'
      post 'create' => 'api/v1/base#create'
      put 'update' => 'api/v1/base#update'
      delete 'destroy' => 'api/v1/base#destroy'
    end
    request.headers['Authorization'] = "Bearer #{generate_token(user.id)}"
    user.update!(current_team_id: team.id)
  end

  describe 'default actions' do
    it 'responds with not implemented to every CRUD action' do
      get :index
      expect(error_title).to eq I18n.t('api.core.errors.not_implemented.title')
      expect(response).to have_http_status(:bad_request)
      get :show
      expect(error_title).to eq I18n.t('api.core.errors.not_implemented.title')
      post :create
      expect(response).to have_http_status(:bad_request)
      put :update
      expect(response).to have_http_status(:bad_request)
      delete :destroy
      expect(response).to have_http_status(:bad_request)
    end

    it 'includes the request id as the error id' do
      get :index
      expect(json['errors'].first).to include('id' => request.uuid, 'status' => 400)
    end
  end

  describe 'error handling' do
    {
      'StandardError' => ['general', :bad_request],
      'Api::V1::BaseController::FilterParamError' => ['filter_parameter', :bad_request],
      'Api::V1::BaseController::TypeError' => ['type', :bad_request],
      'Api::V1::BaseController::IDMismatchError' => ['id_mismatch', :bad_request],
      'Api::V1::BaseController::IncludeNotSupportedError' => ['include_not_supported', :bad_request],
      'NotImplementedError' => ['not_implemented', :bad_request]
    }.each do |kind, (key, status)|
      it "renders #{kind}" do
        get :raise_error, params: { kind: kind }
        expect(response).to have_http_status(status)
        expect(error_title).to eq I18n.t("api.core.errors.#{key}.title")
      end
    end

    it 'renders a permission error as forbidden' do
      get :raise_error, params: { kind: 'Api::V1::BaseController::PermissionError' }
      expect(response).to have_http_status(:forbidden)
      expect(error_title).to eq I18n.t('api.core.errors.read_permission.title')
      expect(json['errors'].first['detail']).to eq I18n.t('api.core.errors.read_permission.detail', model: 'project')
    end

    it 'renders a missing parameter' do
      get :raise_error, params: { kind: 'ActionController::ParameterMissing' }
      expect(response).to have_http_status(:bad_request)
      expect(error_title).to eq I18n.t('api.core.errors.parameter.title')
    end

    it 'renders an incorrect parameter' do
      get :raise_error, params: { kind: 'ActionController::BadRequest' }
      expect(response).to have_http_status(:bad_request)
      expect(error_title).to eq I18n.t('api.core.errors.parameter_incorrect.title')
    end

    it 'renders a record not found with model and id' do
      get :raise_error, params: { kind: 'ActiveRecord::RecordNotFound' }
      expect(response).to have_http_status(:not_found)
      expect(json['errors'].first['detail'])
        .to eq I18n.t('api.core.errors.record_not_found.detail', model: 'Project', id: 42)
    end

    it 'renders a validation error' do
      get :raise_error, params: { kind: 'ActiveRecord::RecordInvalid' }
      expect(response).to have_http_status(:bad_request)
      expect(error_title).to eq I18n.t('api.core.errors.validation.title')
    end

    %w(JWT::DecodeError JWT::InvalidPayload JWT::VerificationError JWT::ExpiredSignature).each do |kind|
      it "renders #{kind} as unauthorized" do
        get :raise_error, params: { kind: kind }
        expect(response).to have_http_status(:unauthorized)
        expect(error_title).to eq I18n.t('api.core.invalid_token')
      end
    end

    it 'renders an api key error as unauthorized' do
      get :raise_error, params: { kind: 'Api::V1::ApiKeyError' }
      expect(response).to have_http_status(:unauthorized)
      expect(json['errors'].first['detail']).to eq I18n.t('api.core.invalid_api_key_detail')
    end

    it 'rejects requests without a token' do
      request.headers['Authorization'] = nil
      get :raise_error, params: { kind: 'StandardError' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'include params' do
    it 'accepts supported includes' do
      get :includes, params: { include: 'a,b' }
      expect(json['includes']).to eq %w(a b)
    end

    it 'returns nil without includes' do
      get :includes
      expect(json['includes']).to be_nil
    end

    it 'rejects unsupported includes' do
      get :includes, params: { include: 'a,z' }
      expect(error_title).to eq I18n.t('api.core.errors.include_not_supported.title')
    end

    it 'rejects unsupported includes on index before the action runs' do
      get :index, params: { include: 'zzz' }
      expect(error_title).to eq I18n.t('api.core.errors.include_not_supported.title')
    end
  end

  describe 'loaders' do
    it 'loads the whole task hierarchy down to protocol content' do
      step_table = create :step_table, step: step
      checklist = create :checklist, step: step
      checklist_item = create :checklist_item, checklist: checklist
      step_text = create :step_text, step: step

      get :chain, params: { team_id: team.id, project_id: project.id, experiment_id: experiment.id,
                            task_id: my_module.id, protocol_id: protocol.id, step_id: step.id,
                            table_id: step_table.table.id, checklist_id: checklist.id,
                            step_text_id: step_text.id, checklist_item_id: checklist_item.id }

      expect(response).to have_http_status(:success)
      expect(json).to include('team' => team.id, 'project' => project.id, 'experiment' => experiment.id,
                              'task' => my_module.id, 'protocol' => protocol.id, 'step' => step.id,
                              'table' => step_table.table.id, 'checklist' => checklist.id,
                              'step_text' => step_text.id, 'checklist_item' => checklist_item.id)
    end

    it 'loads inventory with column and item' do
      inventory = create :repository, team: team, created_by: user
      create_user_assignment(inventory, owner_role, user)
      column = create :repository_column, repository: inventory, created_by: user
      item = create :repository_row, repository: inventory, created_by: user, last_modified_by: user

      get :chain, params: { team_id: team.id, inventory_id: inventory.id, column_id: column.id, item_id: item.id }

      expect(json).to include('inventory' => inventory.id, 'column' => column.id, 'item' => item.id)
    end

    it 'unlocks soft locked inventories' do
      inventory = create :repository, team: team, created_by: user
      create_user_assignment(inventory, owner_role, user)
      inventory.update_columns(type: 'SoftLockedRepository')
      expect_any_instance_of(SoftLockedRepository).to receive(:unlock!).and_call_original
      get :chain, params: { team_id: team.id, inventory_id: inventory.id }
      expect(json['inventory']).to eq inventory.id
    end

    it 'loads a workflow' do
      flow = create :my_module_status_flow
      get :chain, params: { team_id: team.id, workflow_id: flow.id }
      expect(json['workflow']).to eq flow.id
    end

    it 'requires the team id' do
      get :chain
      expect(response).to have_http_status(:bad_request)
      expect(error_title).to eq I18n.t('api.core.errors.parameter.title')
    end

    it 'forbids teams the user cannot read' do
      foreign = create :team
      get :chain, params: { team_id: foreign.id }
      expect(response).to have_http_status(:forbidden)
      expect(error_title).to eq I18n.t('api.core.errors.read_permission.title')
    end

    it 'forbids inventories the user cannot read' do
      inventory = create :repository, team: team, created_by: create(:user)
      get :chain, params: { team_id: team.id, inventory_id: inventory.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids projects the user cannot read' do
      hidden = create :project, team: team, created_by: create(:user), default_public_user_role_id: nil
      get :chain, params: { team_id: team.id, project_id: hidden.id }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns 404 for an unknown project' do
      get :chain, params: { team_id: team.id, project_id: -1 }
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an experiment of another project' do
      other_experiment = create :experiment
      get :chain, params: { team_id: team.id, project_id: project.id, experiment_id: other_experiment.id }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'filters' do
    let!(:alpha) { create :project, team: team, created_by: user, name: 'Alpha project' }
    let!(:beta) { create :project, team: team, created_by: user, name: 'Beta project', archived: true }

    def ids(extra = {})
      get :filters, params: { team_id: team.id }.merge(extra)
      json['ids'] - [project.id]
    end

    it 'does not filter without params' do
      expect(ids).to include(alpha.id, beta.id)
    end

    it 'filters by name' do
      expect(ids(filter: { name: 'Alpha' })).to eq [alpha.id]
    end

    it 'filters by archived state' do
      expect(ids(filter: { archived: 'true' })).to eq [beta.id]
      expect(ids(filter: { archived: 'false' })).to eq [alpha.id]
    end

    it 'defaults to active records when requested' do
      expect(ids(default_to_active: 'true')).to eq [alpha.id]
    end

    it 'rejects an invalid archived value' do
      get :filters, params: { team_id: team.id, filter: { archived: 'maybe' } }
      expect(error_title).to eq I18n.t('api.core.errors.filter_parameter.title')
    end

    it 'filters by creation and update timestamps' do
      alpha.update_columns(created_at: Time.zone.parse('2020-01-10'), updated_at: Time.zone.parse('2020-02-10'))
      beta.update_columns(created_at: Time.zone.parse('2021-01-10'), updated_at: Time.zone.parse('2021-02-10'))
      expect(ids(filter: { created_at: { from: '2020-01-01', to: '2020-12-31' } })).to eq [alpha.id]
      expect(ids(filter: { created_at: { from: '2021-01-01' } })).to eq [beta.id]
      expect(ids(filter: { updated_at: { from: '2021-01-01', to: '2021-12-31' } })).to eq [beta.id]
      expect(ids(filter: { updated_at: { to: '2020-12-31' } })).to eq [alpha.id]
    end

    it 'filters by metadata' do
      tagged = my_module
      tagged.update_columns(metadata: { 'source' => 'lims' })
      other = create :my_module, experiment: experiment, created_by: user
      other.update_columns(metadata: { 'source' => 'other' })

      get :metadata, params: { filter: { metadata: { source: 'lims' } } }
      expect(json['ids']).to eq [tagged.id]

      get :metadata
      expect(json['ids']).to include(tagged.id, other.id)
    end
  end
end
