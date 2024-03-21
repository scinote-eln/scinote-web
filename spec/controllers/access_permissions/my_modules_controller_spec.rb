# frozen_string_literal: true

require 'rails_helper'

describe AccessPermissions::MyModulesController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:experiment) { create :experiment, project: project, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:viewer_user_role) { create :viewer_role }
  let!(:technician_role) { create :technician_role }
  let!(:project) { create :project, team: team, created_by: user }
  let!(:user_project) { create :user_project, user: user, project: project }
  let!(:viewer_user) { create :user, confirmed_at: Time.zone.now }
  let!(:viewer_user_project) { create :user_project, user: viewer_user, project: project }
  let!(:my_module) { create :my_module, experiment: experiment, created_by: experiment.created_by, created_by: user }

  before do
    create_user_assignment(team, owner_role, user)
    create_user_assignment(team, viewer_user_role, viewer_user)
    create_user_assignment(my_module, owner_role, user)
    create_user_assignment(my_module, viewer_user_role, viewer_user)
  end

  describe 'GET #show' do
    it 'returns a http success response' do
      get :show, params: { project_id: project.id, experiment_id: experiment.id, id: my_module.id }, format: :json
      expect(response).to have_http_status :success
    end

    it 'returns json' do
      get :show, params: { project_id: project.id, experiment_id: experiment.id, id: my_module.id }, format: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET #edit' do
    it 'returns a http success response' do
      get :edit, params: { project_id: project.id, experiment_id: experiment.id, id: my_module.id }, format: :json
      expect(response).to have_http_status :success
    end

    it 'renders edit template' do
      get :edit, params: { project_id: project.id, experiment_id: experiment.id, id: my_module.id }, format: :json
      expect(response).to render_template :edit
    end

    it 'renders 403 if user does not have manage permissions on project' do
      sign_in_viewer_user

      get :edit, params: { project_id: project.id, experiment_id: experiment.id, id: my_module.id }, format: :json
      expect(response).to have_http_status :forbidden
    end
  end

  describe 'PUT #update' do
    let(:valid_params) do
      {
        id: my_module.id,
        experiment_id: experiment.id,
        project_id: project.id,
        user_assignment: {
          user_role_id: technician_role.id,
          user_id: viewer_user.id
        }
      }
    end

    it 'updates the user role' do
      put :update, params: valid_params, format: :json
      expect(response).to have_http_status :success
      expect(UserAssignment.find_by(assignable: my_module, user: viewer_user).user_role).to eq technician_role
    end

    it 'does not update the user role when the user has no permissions' do
      sign_in_viewer_user

      put :update, params: valid_params, format: :json

      expect(response).to have_http_status :forbidden
      expect(UserAssignment.find_by(assignable: my_module, user: viewer_user).user_role).to eq viewer_user_role
    end
  end

  def sign_in_viewer_user
    sign_out user
    sign_in viewer_user
  end
end
