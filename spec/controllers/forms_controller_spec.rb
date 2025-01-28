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
end
