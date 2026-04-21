# frozen_string_literal: true

require 'rails_helper'

describe CalendarEventsController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:repository_row) { create :repository_row, repository: repository }
  let(:event_type) { Faker::Name.unique.name }
  let!(:calendar_events) { create_list(:calendar_event, 10, created_by: user, team: team, subject: repository_row, event_type: event_type) }

  describe '#index' do
    let(:params) { { event_type: event_type } }
    let(:params_new_event_type) { { event_type: Faker::Name.unique.name } }

    it 'returns success response with correct event type' do
      get :index, params: params, format: :json
      expect(response).to have_http_status(:success)

      response_body = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response_body['data'].length).to eq 10
    end

    it 'returns success response with event type that do not belong to any event' do
      get :index, params: params_new_event_type, format: :json
      expect(response).to have_http_status(:success)

      response_body = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response_body['data'].length).to eq 0
    end
  end

  describe '#show' do
    it 'unsuccessful response with non existing id' do
      get :show, format: :json, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end

    it 'successful response' do
      get :show, format: :json, params: { id: CalendarEvent.last.id }
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      response_body = JSON.parse(response.body)
      expect(response_body['data']).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(CalendarEvent.last, serializer:  CalendarEventSerializer)
            .to_json
        )['data']
      )
    end
  end

   describe 'POST create' do
    let(:params) {
      {
        repository_row_id: repository_row.id,
        start_at: DateTime.now + 1.days,
        end_at: DateTime.now + 5.days,
        event_type: Faker::Name.unique.name,
        metadata: { test: Faker::Name.unique.name } 
      }
    }
    let(:action) { post :create, params: params, format: :json }

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)
      expect(response_body['data']).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(CalendarEvent.last, serializer:  CalendarEventSerializer)
            .to_json
        )['data']
      )
    end
  end

  describe 'PUT update' do
    let(:action) { put :update, params: params, format: :json }
    let(:params) do
      {
        id: CalendarEvent.last.id,
        start_at: DateTime.now
      }
    end
  
    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)
      expect(response_body['data']).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(CalendarEvent.last, serializer:  CalendarEventSerializer)
            .to_json
        )['data']
      )
    end

    it 'incorrect id' do
      get :update, format: :json, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE destroy' do
    let(:params) { { id: calendar_events.first.id } }
    let(:action) { delete :destroy, params: params }

    it 'destroys' do
      expect { action }.to change(CalendarEvent, :count).by(-1)
      expect(response).to have_http_status(:success)
    end

    it 'incorrect id' do
      delete :destroy, format: :json, params: { id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end

end
