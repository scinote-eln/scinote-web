# frozen_string_literal: true

require 'rails_helper'

describe RepositoryTableFiltersController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:text_column) { create :repository_column, :text_type, created_by: user, repository: repository }
  let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }

  def make_viewer
    UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
  end

  def elements_json(elements)
    elements.to_json
  end

  def filter_params(name, elements)
    { repository_id: repository.id,
      repository_table_filter: { name: name, repository_table_filter_elements_json: elements_json(elements) } }
  end

  let(:custom_element) do
    { 'repository_column_id' => text_column.id, 'operator' => 'contains', 'parameters' => { 'text' => 'abc' } }
  end
  let(:default_element) do
    { 'repository_column_id' => 'name', 'operator' => 'contains', 'parameters' => { 'text' => 'abc' } }
  end

  let!(:filter) do
    create_filter('Existing filter', [custom_element])
  end

  def create_filter(name, elements)
    f = repository.repository_table_filters.new(name: name, created_by: user, default_columns: [])
    elements.each { |e| f.repository_table_filter_elements.build(e) }
    f.save!
    f
  end

  describe 'GET index' do
    it 'returns the filters ordered by name' do
      create_filter('A first filter', [])
      get :index, params: { repository_id: repository.id }, format: :json

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)['data']
      expect(data.map { |d| d['attributes']['name'] }).to eq ['A first filter', 'Existing filter']
      expect(data.last['attributes']['show_url']).to eq repository_repository_table_filter_path(repository, filter)
      expect(data.last['attributes']['delete_url']).to eq repository_repository_table_filter_path(repository, filter)
    end

    it 'is forbidden for a repository the user cannot read' do
      pending 'bug: can_read_repository?(nil) raises ArgumentError (500) instead of rendering 403'
      other_repository = create :repository
      get :index, params: { repository_id: other_repository.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'is forbidden for a missing repository' do
      pending 'bug: can_read_repository?(nil) raises ArgumentError (500) instead of rendering 403'
      get :index, params: { repository_id: 0 }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET show' do
    it 'returns the filter with its elements' do
      get :show, params: { repository_id: repository.id, id: filter.id }, format: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data']['attributes']['name']).to eq 'Existing filter'
      expect(body['included'].size).to eq 1
      expect(body['included'].first['attributes']['repository_column_id']).to eq text_column.id
      expect(body['included'].first['attributes']['operator']).to eq 'contains'
    end

    it 'returns not found for an unknown filter' do
      expect do
        get :show, params: { repository_id: repository.id, id: 0 }, format: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does not load a filter of another repository' do
      other_repository = create :repository, created_by: user, team: team
      other_filter = other_repository.repository_table_filters.create!(name: 'x', created_by: user,
                                                                       default_columns: [])
      expect do
        get :show, params: { repository_id: repository.id, id: other_filter.id }, format: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST create' do
    it 'creates a filter with custom and default columns' do
      expect do
        post :create, params: filter_params('Brand new', [custom_element, default_element]), format: :json
      end.to change(RepositoryTableFilter, :count).by(1).and change(RepositoryTableFilterElement, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data']['attributes']['name']).to eq 'Brand new'
      created = RepositoryTableFilter.find_by(name: 'Brand new')
      expect(created.created_by).to eq user
      expect(created.default_columns.first['repository_column_id']).to eq 'name'
      expect(created.repository_table_filter_elements.first.repository_column).to eq text_column
    end

    it 'returns an error for a blank name' do
      expect do
        post :create, params: filter_params('', [custom_element]), format: :json
      end.not_to change(RepositoryTableFilter, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['message']).to be_present
    end

    it 'returns an error for a column of another repository' do
      foreign_column = create :repository_column
      element = custom_element.merge('repository_column_id' => foreign_column.id)

      expect do
        post :create, params: filter_params('Foreign', [element]), format: :json
      end.not_to change(RepositoryTableFilter, :count)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is forbidden for a viewer' do
      make_viewer
      expect do
        post :create, params: filter_params('Nope', [custom_element]), format: :json
      end.not_to change(RepositoryTableFilter, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PUT update' do
    it 'renames the filter and replaces its elements' do
      other_column = create :repository_column, :text_type, created_by: user, repository: repository
      new_element = custom_element.merge('repository_column_id' => other_column.id)

      put :update, params: filter_params('Renamed', [new_element, default_element]).merge(id: filter.id),
                   format: :json

      expect(response).to have_http_status(:ok)
      filter.reload
      expect(filter.name).to eq 'Renamed'
      expect(filter.repository_table_filter_elements.map(&:repository_column_id)).to eq [other_column.id]
      expect(filter.default_columns.first['repository_column_id']).to eq 'name'
    end

    it 'updates an existing element in place' do
      element = filter.repository_table_filter_elements.first
      changed = custom_element.merge('operator' => 'doesnt_contain', 'parameters' => { 'text' => 'zzz' })

      put :update, params: filter_params('Existing filter', [changed]).merge(id: filter.id), format: :json

      expect(response).to have_http_status(:ok)
      expect(element.reload.operator).to eq 'doesnt_contain'
      expect(element.parameters).to eq('text' => 'zzz')
      expect(filter.repository_table_filter_elements.count).to eq 1
    end

    it 'returns an error for a blank name and keeps the filter' do
      put :update, params: filter_params('', [custom_element]).merge(id: filter.id), format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(filter.reload.name).to eq 'Existing filter'
    end

    it 'returns not found for an unknown filter' do
      expect do
        put :update, params: filter_params('x', [custom_element]).merge(id: 0), format: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'is forbidden for a viewer' do
      make_viewer
      put :update, params: filter_params('Nope', [custom_element]).merge(id: filter.id), format: :json
      expect(response).to have_http_status(:forbidden)
      expect(filter.reload.name).to eq 'Existing filter'
    end
  end

  describe 'DELETE destroy' do
    it 'deletes the filter and its elements' do
      expect do
        delete :destroy, params: { repository_id: repository.id, id: filter.id }, format: :json
      end.to change(RepositoryTableFilter, :count).by(-1).and change(RepositoryTableFilterElement, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it 'returns not found for an unknown filter' do
      expect do
        delete :destroy, params: { repository_id: repository.id, id: 0 }, format: :json
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'is forbidden for a viewer' do
      make_viewer
      expect do
        delete :destroy, params: { repository_id: repository.id, id: filter.id }, format: :json
      end.not_to change(RepositoryTableFilter, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
