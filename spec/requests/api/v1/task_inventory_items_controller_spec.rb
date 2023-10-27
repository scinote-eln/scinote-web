# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::TasksController', type: :request do
  before :all do
    ApplicationSettings.instance.update(
      values: ApplicationSettings.instance.values.merge({"stock_management_enabled" => true})
    )
    MyModuleStatusFlow.ensure_default

    @user = create(:user)
    @team = create(:team, created_by: @user)
    @project = create(:project, name: Faker::Name.unique.name, created_by: @user, team: @team)

    @experiment = create(:experiment, created_by: @user, last_modified_by: @user, project: @project)

    @my_module = create(
      :my_module,
      :with_due_date,
      created_by: @user,
      last_modified_by: @user,
      experiment: @experiment
    )

    @repository = create(:repository, created_by: @user, team: @team)
    @repository_stock_column = create(:repository_column, :stock_type, repository: @repository)
    @repository_row = create(:repository_row, name: 'Test row', repository: @repository)
    @repository_stock_unit_item = create(:repository_stock_unit_item, created_by: @user,
                                                                       last_modified_by: @user,
                                                                       repository_column: @repository_stock_column)
    @repository_stock_value = create(
      :repository_stock_value,
      amount: 100,
      repository_stock_unit_item: @repository_stock_unit_item,
      repository_cell_attributes: { repository_row: @repository_row, repository_column: @repository_stock_column }
    )

    @my_module_repository_row = create(
      :mm_repository_row,
      my_module: @my_module,
      repository_row: @repository_row,
      assigned_by: @user,
      last_modified_by: @user,
      stock_consumption: 5.0
    )

    @valid_headers =
      { 'Authorization': 'Bearer ' + generate_token(@user.id) }
  end

  describe 'GET task_inventory_items, #index' do
    it 'Response with correct task inventory items' do
      get(
        api_v1_team_project_experiment_task_items_url(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @my_module.id
        ),
        headers: @valid_headers
      )

      expect(response).to have_http_status 200
      expect(JSON.parse(response.body)['data'].map { |item| item['id'] }).to(
        eq([@repository_row.id.to_s])
      )
    end
  end

  describe 'GET task inventory items, #show' do
    it 'When valid request, user can read task inventory item' do
      get(
        api_v1_team_project_experiment_task_item_url(
          team_id: @team.id,
          project_id: @project.id,
          experiment_id: @experiment.id,
          task_id: @my_module.id,
          id: @repository_row.id
        ),
        headers: @valid_headers
      )

      expect(response).to have_http_status 200
      expect(JSON.parse(response.body)['data']['id']).to(
        eq(@repository_row.id.to_s)
      )
    end
  end

  describe 'PATCH task inventory items, #update' do
    before :all do
      @valid_headers['Content-Type'] = 'application/json'
    end

    let(:request_body) do
      {
        data: {
          type: 'inventory_items',
          attributes: {
            stock_consumption: 100.0,
            stock_consumption_comment: 'Some comment.'
          }
        }
      }
    end

    context 'when has valid params' do
      let(:action) do
        patch(api_v1_team_project_experiment_task_item_url(
               team_id: @team.id,
               project_id: @project.id,
               experiment_id: @experiment.id,
               task_id: @my_module.id,
               id: @repository_row.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)
      end

      it 'updates stock consumption' do
        action
        expect(@my_module_repository_row.reload.stock_consumption).to eq(100.0)
      end

      it 'returns well formated response' do
        action

        expect(json).to match(
          hash_including(
            data: hash_including(
              type: 'inventory_items',
              attributes: hash_including(stock_consumption: '100.0'))
          )
        )
      end
    end

    context 'when has not valid params' do
      let(:action) do
        patch(api_v1_team_project_experiment_task_item_url(
               team_id: @team.id,
               project_id: @project.id,
               experiment_id: @experiment.id,
               task_id: @my_module.id,
               id: @repository_row.id
             ),
             params: request_body.to_json,
             headers: @valid_headers)
      end

      it 'renders 403 when repository row is locked' do
        @repository.update(archived: true)
        action

        expect(response).to have_http_status(403)
      end
    end
  end
end
