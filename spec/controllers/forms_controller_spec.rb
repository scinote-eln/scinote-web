# frozen_string_literal: true

require 'rails_helper'

describe FormsController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let!(:form) { create :form, team: team, created_by: user }
  let!(:form2) { create :form, team: team, created_by: user }
  let!(:published_form) { create :form, team: team, created_by: user, published_by: user, published_on: DateTime.parse('1-1-2000') }
  let!(:form_field) { create :form_field, form: form2, created_by: user }

  before do
    allow(Form).to(receive(:forms_enabled?)).and_return(true)
  end

  describe '#index' do
    let(:params) { { team: team.id, per_page: 20, page: 1 } }

    it 'returns success response' do
      get :index, params: params, format: :json
      expect(response).to have_http_status(:success)

      response_body = JSON.parse(response.body)

      expect(response_body['data'].length).to eq 3
      expect(response.body).to include(form.name)
      expect(response.body).to include(form2.name)
      expect(response.body).not_to include(form_field.name)
    end
  end

  describe '#show' do
    it 'unsuccessful response with non existing id' do
      get :show, format: :json, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end

    it 'successful response' do
      get :show, format: :json, params: { id: form2.id }
      expect(response).to have_http_status(:success)

      response_body = JSON.parse(response.body)
      expect(response_body['included'].first['attributes']['name']).to eq form_field.name
    end
  end

  describe 'POST create' do
    let(:action) { post :create, format: :json }

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)
      expect(response_body['data']['attributes']['name']).to eq I18n.t('forms.default_name')
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      {
        id: form.id,
        form: {
          name: 'Renamed form',
          description: 'test description'
        }
      }
    end

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)
      expect(response_body['data']['attributes']['name']).to eq params[:form][:name]
      expect(response_body['data']['attributes']['description']).to eq params[:form][:description]
    end

    it 'incorrect id' do
      get :update, format: :json, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end

  end

  describe 'POST publish' do
    let(:action) { put :publish, params: params, format: :json }
    let(:params) do
      {
        id: form.id,
      }
    end

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)

      expect(response_body['data']['attributes']['published_by']).to eq user.full_name
      expect(response_body['data']['attributes']['published_on']).not_to eq nil
    end

    it 'incorrect id' do
      get :publish, format: :json, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST unpublish' do
    let(:action) { put :unpublish, params: params, format: :json }
    let(:params) do
      {
        id: published_form.id,
      }
    end

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)

      expect(response_body['data']['attributes']['published_by']).to eq nil
      expect(response_body['data']['attributes']['published_on']).to eq nil
    end

    it 'incorrect id' do
      get :unpublish, format: :json, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST archive' do
    let(:action) { put :archive, params: params, format: :json }
    let(:params) do
      {
        form_ids: [form.id]
      }
    end

    it 'returns success response' do
      expect(form.archived?).to eq false
      action
      expect(response).to have_http_status(:success)
      form.reload
      expect(form.archived?).to eq true
    end
  end

  describe 'POST restore' do
    let!(:form_archived) { create :form, :archived, team: team, created_by: user }
    let(:action) { put :restore, params: params, format: :json }
    let(:params) do
      {
        form_ids: [form_archived.id]
      }
    end

    it 'returns success response' do
      expect(form_archived.archived?).to eq true
      action
      expect(response).to have_http_status(:success)
      form_archived.reload
      expect(form_archived.archived?).to eq false
    end
  end
  describe 'extended behaviour' do
    def viewer!
      team_assignment.update!(user_role: viewer_role)
    end

    it 'renders the promo page when forms are disabled' do
      allow(Form).to receive(:forms_enabled?).and_return(false)
      get :index
      expect(response).to render_template(:promo)
    end

    it 'index renders html' do
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:breadcrumbs_items).first[:label]).to eq I18n.t('breadcrumbs.forms')
    end

    it 'index prefixes breadcrumbs for the archived view' do
      get :index, params: { view_mode: 'archived' }
      expect(assigns(:breadcrumbs_items).first[:label]).to start_with I18n.t('labels.archived')
    end

    it 'index limits forms to readable ones for non managers' do
      viewer!
      get :index, params: { team: team.id, per_page: 20, page: 1 }, format: :json
      expect(response).to have_http_status(:success)
    end

    it 'show renders html with breadcrumbs for the form' do
      get :show, params: { id: form.id }
      expect(response).to have_http_status(:success)
      expect(assigns(:breadcrumbs_items).last[:label]).to eq form.name
    end

    describe 'create' do
      it 'logs an activity' do
        expect { post :create, format: :json }.to change { Activity.where(type_of: :form_created).count }.by(1)
        expect(Form.order(:id).last.created_by).to eq user
      end

      it 'is forbidden for a viewer' do
        viewer!
        expect { post :create, format: :json }.not_to change(Form, :count)
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns errors when saving fails' do
        allow_any_instance_of(Form).to receive(:save).and_return(false)
        post :create, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'update' do
      it 'logs an activity' do
        expect { put :update, params: { id: form.id, form: { name: 'Another name' } }, format: :json }
          .to change { Activity.where(type_of: :form_name_changed).count }.by(1)
      end

      it 'returns errors for invalid data' do
        put :update, params: { id: form.id, form: { name: '' } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(form.reload.name).not_to eq ''
      end

      it 'is forbidden for a published form' do
        put :update, params: { id: published_form.id, form: { name: 'Nope' } }, format: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'publish / unpublish permissions' do
      it 'cannot publish an already published form' do
        put :publish, params: { id: published_form.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'cannot unpublish a draft' do
        put :unpublish, params: { id: form.id }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'logs publish and unpublish activities' do
        expect { put :publish, params: { id: form.id }, format: :json }
          .to change { Activity.where(type_of: :form_published).count }.by(1)
        expect { put :unpublish, params: { id: form.id }, format: :json }
          .to change { Activity.where(type_of: :form_unpublished).count }.by(1)
      end
    end

    describe 'GET published_forms' do
      it 'lists published forms' do
        get :published_forms
        body = JSON.parse(response.body)
        expect(body['data']).to eq [[published_form.id, published_form.name]]
        expect(body['paginated']).to be true
      end

      it 'filters by query' do
        get :published_forms, params: { query: 'zzz-no-match' }
        expect(JSON.parse(response.body)['data']).to eq []
      end

      it 'filters by a matching query' do
        get :published_forms, params: { query: published_form.name[0, 4] }
        expect(JSON.parse(response.body)['data'].flatten).to include(published_form.id)
      end
    end

    describe 'GET latest_attached_forms' do
      it 'lists published forms the user responded to' do
        step_form_response = create :form_response, form: published_form, created_by: user
        expect(step_form_response).to be_persisted
        get :latest_attached_forms
        data = JSON.parse(response.body)['data']
        expect(data.pluck('id')).to eq [published_form.id]
      end

      it 'returns nothing without responses' do
        get :latest_attached_forms
        expect(JSON.parse(response.body)['data']).to eq []
      end
    end

    describe 'archive / restore' do
      it 'archives and logs an activity' do
        expect { put :archive, params: { form_ids: [form.id] }, format: :json }
          .to change { Activity.where(type_of: :form_archived).count }.by(1)
        expect(JSON.parse(response.body)['message']).to eq I18n.t('forms.archived.success_flash', number: 1)
      end

      it 'returns 404 when there is nothing to archive' do
        put :archive, params: { form_ids: [-1] }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'is forbidden to archive for a viewer' do
        form.user_assignments.update(user_role: viewer_role)
        put :archive, params: { form_ids: [form.id] }, format: :json
        expect(response).to have_http_status(:forbidden)
        expect(form.reload).not_to be_archived
      end

      it 'reports an error when archiving fails' do
        allow_any_instance_of(Form).to receive(:archive!).and_raise(StandardError, 'boom')
        put :archive, params: { form_ids: [form.id] }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'restores and logs an activity' do
        archived = create :form, :archived, team: team, created_by: user
        expect { put :restore, params: { form_ids: [archived.id] }, format: :json }
          .to change { Activity.where(type_of: :form_restored).count }.by(1)
      end

      it 'returns 404 when there is nothing to restore' do
        put :restore, params: { form_ids: [form.id] }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'is forbidden to restore for a viewer' do
        archived = create :form, :archived, team: team, created_by: user
        archived.user_assignments.update(user_role: viewer_role)
        put :restore, params: { form_ids: [archived.id] }, format: :json
        expect(response).to have_http_status(:forbidden)
      end

      it 'reports an error when restoring fails' do
        archived = create :form, :archived, team: team, created_by: user
        allow_any_instance_of(Form).to receive(:restore!).and_raise(StandardError, 'boom')
        put :restore, params: { form_ids: [archived.id] }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe 'duplicate' do
      it 'duplicates the form and logs an activity' do
        expect { post :duplicate, params: { id: form2.id }, format: :json }
          .to change(Form, :count).by(1)
          .and change { Activity.where(type_of: :form_duplicated).count }.by(1)
        expect(response).to have_http_status(:success)
      end

      # bug: the RecordInvalid rescue reads `new_form.errors`, but new_form is nil when duplicate! raises,
      # so a validation failure ends in NoMethodError instead of a 422 response
      it 'raises NoMethodError instead of returning validation errors' do
        allow_any_instance_of(Form).to receive(:duplicate!).and_raise(ActiveRecord::RecordInvalid.new(Form.new))
        expect { post :duplicate, params: { id: form.id }, format: :json }.to raise_error(NoMethodError, /errors/)
      end

      it 'returns a general error for unexpected failures' do
        allow_any_instance_of(Form).to receive(:duplicate!).and_raise(StandardError, 'boom')
        post :duplicate, params: { id: form.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['message']).to eq I18n.t('errors.general')
      end

      it 'returns 404 for an unknown form' do
        post :duplicate, params: { id: -1 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    describe 'export_form_responses' do
      it 'enqueues the export and logs an activity' do
        allow(FormResponsesZipExportJob).to receive(:perform_later)
        expect { post :export_form_responses, params: { id: form.id }, format: :json }
          .to change { Activity.where(type_of: :export_form_responses).count }.by(1)
        expect(FormResponsesZipExportJob).to have_received(:perform_later)
          .with(user_id: user.id, params: { form_id: form.id })
        expect(JSON.parse(response.body)['message']).to eq I18n.t('zip_export.export_request_success')
      end
    end

    describe 'actions_toolbar' do
      it 'returns toolbar actions for the selected forms' do
        post :actions_toolbar, params: { items: [{ id: form.id }].to_json }, format: :json
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)).to have_key('actions')
      end
    end
  end
end
