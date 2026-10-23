# frozen_string_literal: true

require 'rails_helper'

describe RepositoryColumns::StockColumnsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }

  def make_viewer
    UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
  end

  describe 'POST create' do
    let(:params) do
      { repository_id: repository.id,
        repository_column: { name: 'Stock', metadata: { decimals: 2 },
                             repository_stock_unit_items_attributes: [{ data: 'ml' }, { data: 'l' }] } }
    end

    it 'creates a stock column with its unit items' do
      expect(Activities::CreateActivityService)
        .to receive(:call).with(hash_including(activity_type: :create_column_inventory))

      expect { post :create, params: params, format: :json }.to change(RepositoryColumn, :count).by(1)

      expect(response).to have_http_status(:created)
      column = repository.repository_columns.find_by(name: 'Stock')
      expect(column.data_type).to eq 'RepositoryStockValue'
      expect(column.repository_stock_unit_items.pluck(:data)).to contain_exactly('l', 'ml')
      expect(column.repository_stock_unit_items.map(&:created_by).uniq).to eq [user]
    end

    it 'returns validation errors for a blank name' do
      params[:repository_column][:name] = ''
      expect { post :create, params: params, format: :json }.not_to change(RepositoryColumn, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['repository_column']).to have_key('name')
    end

    it 'is forbidden for a viewer' do
      make_viewer
      expect { post :create, params: params, format: :json }.not_to change(RepositoryColumn, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update' do
    let!(:column) { create :repository_column, :stock_type, name: 'Stock', repository: repository, created_by: user }
    let!(:ml_item) { create :repository_stock_unit_item, data: 'ml', repository_column: column, created_by: user }
    let!(:l_item) { create :repository_stock_unit_item, data: 'l', repository_column: column, created_by: user }
    let(:params) do
      { repository_id: repository.id, id: column.id,
        repository_column: { name: 'Renamed', metadata: { decimals: 1 },
                             repository_stock_unit_items_attributes: [{ data: 'ml' }, { data: 'kg' }] } }
    end

    it 'renames the column, removes missing units and adds new ones' do
      expect(Activities::CreateActivityService)
        .to receive(:call).with(hash_including(activity_type: :edit_column_inventory))

      put :update, params: params, format: :json

      expect(response).to have_http_status(:ok)
      column.reload
      expect(column.name).to eq 'Renamed'
      expect(column.repository_stock_unit_items.pluck(:data)).to contain_exactly('ml', 'kg')
      expect(RepositoryStockUnitItem.exists?(l_item.id)).to be false
      expect(RepositoryStockUnitItem.exists?(ml_item.id)).to be true
    end

    it 'rejects more units than the column limit' do
      stub_const('Constants::REPOSITORY_STOCK_UNIT_ITEMS_PER_COLUMN', 2)
      params[:repository_column][:repository_stock_unit_items_attributes] = [{ data: 'ml' }, { data: 'a' }, { data: 'b' }]

      put :update, params: params, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['repository_column']['repository_stock_unit_items']).to eq 'too many items'
      expect(column.reload.name).to eq 'Stock'
    end

    it 'returns validation errors for a blank name' do
      params[:repository_column][:name] = ''

      put :update, params: params, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['repository_column']).to have_key('name')
    end

    it 'is forbidden for a viewer' do
      make_viewer
      put :update, params: params, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(column.reload.name).to eq 'Stock'
    end
  end

  describe 'GET items' do
    let!(:column) { create :repository_column, :stock_type, repository: repository, created_by: user }
    let!(:items) do
      %w(mg ml <b>l).map { |d| create :repository_stock_unit_item, data: d, repository_column: column, created_by: user }
    end

    it 'returns all units ordered by name when there is no query' do
      get :items, params: { repository_id: repository.id, id: column.id }, format: :json

      expect(response).to have_http_status(:ok)
      labels = JSON.parse(response.body).map { |i| i['label'] }
      expect(labels.size).to eq 3
      expect(labels).to match_array ['mg', 'ml', '&lt;b&gt;l']
      expect(labels.index('mg')).to be < labels.index('ml')
    end

    it 'filters units by a case-insensitive query and escapes the label' do
      get :items, params: { repository_id: repository.id, id: column.id, query: 'M' }, format: :json

      body = JSON.parse(response.body)
      expect(body.map { |i| i['label'] }).to eq %w(mg ml)
      expect(body.map { |i| i['value'] }).to eq [items[0].id, items[1].id]
    end

    it 'returns the label html-escaped' do
      get :items, params: { repository_id: repository.id, id: column.id, query: '<b>' }, format: :json

      body = JSON.parse(response.body)
      expect(body).to eq [{ 'value' => items[2].id, 'label' => '&lt;b&gt;l' }]
    end

    it 'returns not found for an unknown column' do
      get :items, params: { repository_id: repository.id, id: 0 }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for a repository the user cannot read' do
      other = create :repository
      other_column = create :repository_column, :stock_type, repository: other
      get :items, params: { repository_id: other.id, id: other_column.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
