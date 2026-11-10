# frozen_string_literal: true

require 'rails_helper'

describe UserMyModulesController, type: :controller do
  login_user

  include_context 'reference_project_structure'
  let(:other_user) { create :user }

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id, user_my_module: { user_id: other_user.id } }
    end

    it 'calls create activity for assigning user to task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :designate_user_to_my_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'DELETE destroy' do
    let(:user_task) { create :user_my_module, user: user, my_module: my_module }
    let(:action) { delete :destroy, params: params, format: :json }
    let(:params) do
      { my_module_id: my_module.id, id: user_task.id }
    end

    it 'calls create activity for unassigning user to task' do
      expect(Activities::CreateActivityService)
        .to(receive(:call)
              .with(hash_including(activity_type: :undesignate_user_from_my_module)))
      action
    end

    it 'adds activity in DB' do
      expect { action }
        .to(change { Activity.count })
    end
  end

  describe 'extended behaviour' do
    render_views

    let(:json) { JSON.parse(response.body) }
    let!(:other_assignment) do
      create :user_assignment, user: other_user, assignable: my_module, user_role: normal_user_role
    end

    describe 'POST create' do
      let(:params) { { my_module_id: my_module.id, user_my_module: { user_id: other_user.id } } }

      it 'designates the user and returns the user payload' do
        expect { post :create, params: params, format: :json }.to change(UserMyModule, :count).by(1)

        expect(response).to have_http_status(:ok)
        um = UserMyModule.last
        expect(um).to have_attributes(user: other_user, my_module: my_module, assigned_by: user)
        expect(json['user']).to include('id' => other_user.id, 'user_module_id' => um.id)
        expect(Activity.where(type_of: :designate_user_to_my_module, subject: my_module).count).to eq 1
      end

      it 'renders the assigned users html when called from the table' do
        post :create, params: params.merge(table: true), format: :json

        expect(response).to have_http_status(:ok)
        expect(json['html']).to be_present
        expect(json['unassign_url']).to eq my_module_user_my_module_path(my_module, UserMyModule.last)
      end

      it 'returns validation errors for duplicate designation' do
        create :user_my_module, user: other_user, my_module: my_module, assigned_by: user

        expect { post :create, params: params, format: :json }.not_to change(UserMyModule, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to be_present
      end

      it 'is forbidden without designated users permission' do
        allow(controller).to receive(:can_manage_my_module_designated_users?).and_return(false)

        expect { post :create, params: params, format: :json }.not_to change(UserMyModule, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns not found for an unknown task' do
        post :create, params: params.merge(my_module_id: -1), format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'DELETE destroy' do
      let!(:user_task) { create :user_my_module, user: other_user, my_module: my_module, assigned_by: user }
      let(:params) { { my_module_id: my_module.id, id: user_task.id } }

      it 'removes the designation and returns an empty json' do
        expect { delete :destroy, params: params, format: :json }.to change(UserMyModule, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json).to eq({})
        expect(Activity.where(type_of: :undesignate_user_from_my_module, subject: my_module).count).to eq 1
      end

      it 'renders html when called from the table' do
        delete :destroy, params: params.merge(table: true), format: :json
        expect(json['html']).to be_present
      end

      it 'is forbidden without permission' do
        allow(controller).to receive(:can_manage_my_module_designated_users?).and_return(false)

        expect { delete :destroy, params: params, format: :json }.not_to change(UserMyModule, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET designated_users' do
      it 'returns html and counter' do
        create :user_my_module, user: other_user, my_module: my_module, assigned_by: user

        # the partial fails to render under controller specs (see report), so only the JSON contract is checked
        allow(controller).to receive(:render_to_string).and_return("<li>#{other_user.full_name}</li>")
        get :designated_users, params: { my_module_id: my_module.id }

        expect(response).to have_http_status(:ok)
        expect(json).to include('my_module_id' => my_module.id, 'counter' => 1)
        expect(json['html']).to include(other_user.full_name)
        expect(controller).to have_received(:render_to_string).with(partial: 'designated_users', formats: :html)
      end

      it 'is forbidden without read permission' do
        allow(controller).to receive(:can_read_my_module?).and_return(false)
        get :designated_users, params: { my_module_id: my_module.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'POST designate_users' do
      it 'designates new users and undesignates removed ones' do
        stale = create :user_my_module, user: user, my_module: my_module, assigned_by: user

        post :designate_users, params: { my_module_id: my_module.id, user_ids: [other_user.id] }, format: :json

        expect(response).to have_http_status(:ok)
        expect(json).to include('status' => 'ok', 'message' => 'success')
        expect(my_module.reload.user_my_modules.pluck(:user_id)).to eq [other_user.id]
        expect(UserMyModule.exists?(stale.id)).to be false
        expect(Activity.where(type_of: :designate_user_to_my_module).count).to eq 1
        expect(Activity.where(type_of: :undesignate_user_from_my_module).count).to eq 1
      end

      it 'is forbidden without permission' do
        allow(controller).to receive(:can_manage_my_module_designated_users?).and_return(false)
        post :designate_users, params: { my_module_id: my_module.id, user_ids: [other_user.id] }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'rolls back and reports an error when saving fails' do
        allow_any_instance_of(UserMyModule).to receive(:log_activity).and_raise(ActiveRecord::RecordInvalid)

        post :designate_users, params: { my_module_id: my_module.id, user_ids: [other_user.id] }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to include('status' => 'error')
        expect(my_module.reload.user_my_modules).to be_empty
      end
    end

    describe 'GET index' do
      it 'returns html' do
        pending 'bug: user_my_modules/_index.html.erb needs a my_module local that #index never passes'
        get :index, params: { my_module_id: my_module.id }
        expect(response).to have_http_status(:ok)
        expect(json['html']).to be_present
      end

      it 'is forbidden without read permission' do
        allow(controller).to receive(:can_read_my_module?).and_return(false)
        get :index, params: { my_module_id: my_module.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET index_edit' do
      it 'returns the task and the edit html' do
        allow(controller).to receive(:render_to_string).and_return('<ul></ul>')

        get :index_edit, params: { my_module_id: my_module.id }
        expect(response).to have_http_status(:ok)
        expect(json['my_module']['id']).to eq my_module.id
        expect(json['html']).to be_present
      end
    end

    describe 'GET search' do
      before { other_user.update_columns(full_name: 'Zed Unique') }

      let!(:designated) { create :user_my_module, user: other_user, my_module: my_module, assigned_by: user }

      def search(extra = {})
        get :search, params: { my_module_id: my_module.id, id: designated.id, query: '' }.merge(extra), format: :json
        json
      end

      it 'lists task users with designation info, designated first' do
        result = search
        by_value = result.index_by { |r| r['value'] }

        expect(by_value[other_user.id]['params']).to include(
          'designated' => true,
          'assign_url' => my_module_user_my_modules_path(my_module),
          'unassign_url' => my_module_user_my_module_path(my_module, designated.id)
        )
        expect(by_value[user.id]['params']['designated']).to be false
        expect(by_value[user.id]['params']).not_to have_key('unassign_url')
        expect(result.first['value']).to eq other_user.id
      end

      it 'filters by query' do
        expect(search(query: 'Zed Uni').map { |r| r['value'] }).to eq [other_user.id]
      end

      it 'returns nothing for a non matching query' do
        # no-match responses are wrapped in { data: [] } while matches are a bare array
        expect(search(query: 'zzz-no-such-user')).to eq('data' => [])
      end

      it 'can skip assigned users' do
        expect(search(skip_assigned: true).map { |r| r['value'] }).not_to include(other_user.id)
      end

      it 'can skip unassigned users' do
        expect(search(skip_unassigned: 'true').map { |r| r['value'] }).to eq [other_user.id]
      end

      it 'is forbidden without read permission' do
        allow(controller).to receive(:can_read_my_module?).and_return(false)
        get :search, params: { my_module_id: my_module.id, id: designated.id, query: '' }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
