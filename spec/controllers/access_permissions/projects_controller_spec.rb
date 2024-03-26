# frozen_string_literal: true

require 'rails_helper'

describe AccessPermissions::ProjectsController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:project) { create :project, team: team, created_by: user }
  let!(:owner_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.owner')) }
  let!(:normal_user_role) { create :normal_user_role }
  let!(:technician_role) { create :technician_role }
  let!(:user_project) { create :user_project, user: user, project: project }
  let!(:normal_user) { create :user, confirmed_at: Time.zone.now }

  before do
    create_user_assignment(team, owner_role, user)
    create_user_assignment(team, normal_user_role, normal_user)
  end

  describe 'GET #new' do
    it 'returns a http success response' do
      get :new, params: { id: project.id }, format: :json
      expect(response).to have_http_status :success
    end

    it 'renders an array of users' do
      get :new, params: { id: project.id }, format: :json

      json_response = JSON.parse(response.body)

      # Check that the top level is an array
      expect(json_response["data"]).to be_an_instance_of(Array)
    end

    it 'renders 404 if project is not set' do
      get :new, params: { id: nil }, format: :json
      expect(response).to have_http_status :not_found
    end

    it 'renders 403 if user does not have manage permissions' do
      sign_in_normal_user
      get :new, params: { id: project.id }, format: :json
      expect(response).to have_http_status :forbidden
    end
  end

  describe 'GET #show' do
    it 'returns a http success response' do
      get :show, params: { id: project.id }, format: :json
      expect(response).to have_http_status :success
    end

    it 'renders and array of user_assignment' do
      get :show, params: { id: project.id }, format: :json
      json_response = JSON.parse(response.body)

      expect(json_response["data"]).to be_an_instance_of(Array)
    end
  end

  describe 'GET #edit' do
    it 'returns a http success response' do
      get :edit, params: { id: project.id }, format: :json
      expect(response).to have_http_status :success
    end

    it 'renders edit template' do
      get :edit, params: { id: project.id }, format: :json
      expect(response).to render_template :edit
    end

    it 'renders 403 if user does not have manage permissions on project' do
      create :user_project, user: normal_user, project: project
      create :user_assignment, assignable: project, user: normal_user, user_role: normal_user_role, assigned_by: user

      sign_in_normal_user

      get :edit, params: { id: project.id }, format: :json
      expect(response).to have_http_status :forbidden
    end
  end

  describe 'PUT #update' do
    let!(:normal_user_project) { create :user_project, user: normal_user, project: project }
    let!(:normal_user_assignment) do
      create :user_assignment,
             assignable: project,
             user: normal_user,
             user_role: normal_user_role,
             assigned_by: user
    end

    let(:valid_params) do
      {
        id: project.id,
        user_assignment: {
          user_role_id: technician_role.id,
          user_id: normal_user.id
        }
      }
    end

    it 'updates the user role' do
      put :update, params: valid_params, format: :json
      expect(response).to have_http_status :success
      expect(normal_user_assignment.reload.user_role).to eq technician_role
    end

    it 'does not update the user role when the user has no permissions' do
      sign_in_normal_user

      put :update, params: valid_params, format: :json

      expect(response).to have_http_status :forbidden
      expect(normal_user_assignment.reload.user_role).to eq normal_user_role
    end
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        id: project.id,
        user_assignment: {
          user_id: normal_user.id,
          user_role_id: technician_role.id
        }
      }
    end

    let!(:initial_count) do
      UserAssignment.count
    end

    it 'creates new project user and user assignment' do
      Delayed::Worker.delay_jobs = false
      dj_worker = Delayed::Worker.new
      post :create, params: valid_params, format: :json
      Delayed::Job.all.each { |job| dj_worker.run(job) }
      expect(UserAssignment.count - initial_count).to eq(1)
    end

    it 'does not create an assigment if user is already assigned' do
      create :user_assignment, user: normal_user,
                               user_role: technician_role,
                               assignable: project,
                               assigned_by: user
      expect {
        post :create, params: valid_params, format: :json
      }.to change(UserAssignment, :count).by(0)
    end

    it 'does not create an assigment when the user is already assigned with different permission' do
      create :user_project, user: normal_user, project: project
      create :user_assignment, assignable: project, user: normal_user, user_role: normal_user_role, assigned_by: user

      expect {
        post :create, params: valid_params, format: :json
      }.to change(UserProject, :count).by(0).and \
        change(UserAssignment, :count).by(0)
    end

    it 'renders 403 if user does not have manage permissions on project' do
      sign_in_normal_user

      post :create, params: valid_params, format: :json
      expect(response).to have_http_status :forbidden
    end
  end

  describe 'DELETE #destroy' do
    let!(:normal_user_project) { create :user_project, user: normal_user, project: project }
    let!(:normal_user_assignment) do
      create :user_assignment,
             assignable: project,
             user: normal_user,
             user_role: normal_user_role,
             assigned_by: user
    end

    let(:valid_params) do
      {
        id: project.id,
        user_id: normal_user.id
      }
    end

    it 'removes the user project and user assigment record' do
      expect {
        delete :destroy, params: valid_params, format: :json
      }.to change(UserAssignment, :count).by(-1)
    end

    it 'renders 403 if user does not have manage permissions on project' do
      sign_in_normal_user

      delete :destroy, params: valid_params, format: :json
      expect(response).to have_http_status :forbidden
    end
  end

  def sign_in_normal_user
    sign_out user
    sign_in normal_user
  end
end
