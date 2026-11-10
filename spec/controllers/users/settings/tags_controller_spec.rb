# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::TagsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }
  let!(:tag_a) { create :tag, team: team, created_by: user, name: 'Alpha tag' }
  let!(:tag_b) { create :tag, team: team, created_by: user, name: 'Beta tag' }

  def make_team_viewer!
    team.user_assignments.find_by(user: user).update!(user_role: viewer_role)
  end

  def names
    JSON.parse(response.body)['data'].map { |d| d['attributes']['name'] }
  end

  describe 'GET index' do
    it 'renders html and sets the active tab and breadcrumbs' do
      get :index, params: { team_id: team.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:active_tab)).to eq :tags
      expect(assigns(:breadcrumbs_items).pluck(:label)).to include(team.name)
    end

    it 'lists the team tags as json' do
      create :tag # other team
      get :index, params: { team_id: team.id }, format: :json
      expect(names).to match_array(['Alpha tag', 'Beta tag'])
    end

    it 'filters by search' do
      get :index, params: { team_id: team.id, search: 'Alpha' }, format: :json
      expect(names).to eq ['Alpha tag']
    end

    it 'sorts by name descending' do
      get :index, params: { team_id: team.id, order: { column: 'name', dir: 'desc' } }, format: :json
      expect(names).to eq ['Beta tag', 'Alpha tag']
    end

    it 'sorts by taggings count' do
      project = create :project, team: team, created_by: user
      experiment = create :experiment, project: project, created_by: user
      my_module = create :my_module, experiment: experiment, created_by: user
      create :tag, team: team, created_by: user, name: 'Zeta tag'
      Tagging.create!(tag: tag_b, taggable: my_module, created_by: user)
      get :index, params: { team_id: team.id, order: { column: 'taggings_count', dir: 'desc' } }, format: :json
      expect(names.first).to eq 'Beta tag'
      counts = JSON.parse(response.body)['data'].map { |d| d['attributes']['taggings_count'] }
      expect(counts.first).to eq 1
    end

    it 'returns 404 for a team the user does not belong to' do
      get :index, params: { team_id: create(:team).id }, format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      get :index, params: { team_id: team.id }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST actions_toolbar' do
    it 'returns merge and delete actions for the owner' do
      post :actions_toolbar, params: { team_id: team.id, items: [{ id: tag_a.id }].to_json }, format: :json
      actions = JSON.parse(response.body)['actions']
      expect(actions.pluck('name')).to eq %w(merge delete)
    end

    it 'is forbidden for a team viewer' do
      make_team_viewer!
      post :actions_toolbar, params: { team_id: team.id, items: [{ id: tag_a.id }].to_json }, format: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
