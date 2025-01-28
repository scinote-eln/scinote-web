# frozen_string_literal: true

require 'rails_helper'

describe FormFieldsController, type: :controller do
  login_user

  include_context 'reference_project_structure'

  let!(:form) { create :form, team: team, created_by: user }
  let!(:form_field) { create :form_field, position: 0, form: form, created_by: user }
  let!(:form_fields) do
    5.times.map.with_index do |_, i|
      create :form_field, position: i + 1, form: form, created_by: user
    end
  end

  before do
    allow(Form).to(receive(:forms_enabled?)).and_return(true)
  end

  describe 'POST create' do
    let(:action) { post :create, params: params, format: :json }
    let(:params) do
      {
        form_id: form.id,
        form_field: {
          name: Faker::Name.unique.name,
          description: Faker::Lorem.sentence,
          data: { type: 'text' },
          required: true,
          allow_not_applicable: true,
          uid: Faker::Name.unique.name
        }
      }
  end

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)
      expect(response_body['data']['attributes']['name']).to eq params[:form_field][:name]
      expect(response_body['data']['attributes']['description']).to eq params[:form_field][:description]
      expect(response_body['data']['attributes']['required']).to eq params[:form_field][:required]
      expect(response_body['data']['attributes']['allow_not_applicable']).to eq params[:form_field][:allow_not_applicable]
      expect(response_body['data']['attributes']['uid']).to eq params[:form_field][:uid]
      expect(response_body['data']['attributes']['position']).to eq(form_fields.length + 1)
    end

    it 'invalid params' do
      params[:form_field][:name] = ''
      action
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      {
        form_id: form.id,
        id: form_field.id,
        form_field: {
          name: Faker::Name.unique.name,
          description: Faker::Lorem.sentence,
          data: { type: 'text' },
          required: true,
          allow_not_applicable: true,
          uid: Faker::Name.unique.name
        }
      }
  end

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)
      expect(response_body['data']['attributes']['name']).to eq params[:form_field][:name]
      expect(response_body['data']['attributes']['description']).to eq params[:form_field][:description]
      expect(response_body['data']['attributes']['required']).to eq params[:form_field][:required]
      expect(response_body['data']['attributes']['allow_not_applicable']).to eq params[:form_field][:allow_not_applicable]
      expect(response_body['data']['attributes']['uid']).to eq params[:form_field][:uid]
      expect(response_body['data']['attributes']['position']).to eq(form_field.position)
    end

    it 'invalid params' do
      params[:form_field][:name] = ''
      action
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE destroy' do

    let(:action) { delete :destroy, params: params }
    let(:params) do
      {
        form_id: form.id,
        id: form_field.id,
      }
    end

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
    end

    it 'invalid id' do
      params[:id] = -1
      action
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST reorder' do

    let(:action) { delete :reorder, params: params }
    let(:params) do
      {
        form_id: form.id,
        form_field_positions: form_positions
      }
    end

    let(:form_positions) do
      positions = form.form_fields.pluck(:position).reverse
      form.form_fields.pluck(:id).each_with_index.map do |id, i|
        { id: id, position: positions[i] }
      end
    end

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)

      new_form_fields_order = form.form_fields.order(position: :asc).pluck(:id, :position)

      expect(new_form_fields_order).to(
        eq(form_positions.map(&:values).sort { |a, b| a[1] <=> b[1] })
      )
    end
  end
end
