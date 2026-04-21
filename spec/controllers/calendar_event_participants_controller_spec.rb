# frozen_string_literal: true

require 'rails_helper'

describe CalendarEventParticipantsController, type: :controller do
  login_user

  let!(:user) { controller.current_user }
  let!(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:repository_row) { create :repository_row, repository: repository }
  let(:event_type) { Faker::Name.unique.name }
  let!(:calendar_event) { create :calendar_event, created_by: user, team: team, subject: repository_row, event_type: event_type }
  let!(:calendar_event_participant) { create :calendar_event_participant, user: user, calendar_event: calendar_event}

  describe '#index' do
    let(:params) { { calendar_event_id: calendar_event.id } }

    it 'returns success response with correct event type' do
      get :index, params: params, format: :json
      expect(response).to have_http_status(:success)

      response_body = JSON.parse(response.body)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(response_body['data'].length).to eq 1
    end
  end

   describe 'POST create' do
    let(:params) {
      {
        calendar_event_id: calendar_event_second.id,
        user_id: user.id 
      }
    }
    let(:action) { post :create, params: params, format: :json }
    let(:calendar_event_second) { create :calendar_event, created_by: user, team: team, subject: repository_row, event_type: event_type }

    it 'returns success response' do
      action
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
      response_body = JSON.parse(response.body)
      expect(response_body['data']).to match(
        JSON.parse(
          ActiveModelSerializers::SerializableResource
            .new(CalendarEventParticipant.last, serializer:  CalendarEventParticipantSerializer)
            .to_json
        )['data']
      )
    end
  end

  describe 'DELETE destroy' do
    let(:params) { { calendar_event_id: calendar_event.id,  id: calendar_event_participant.id } }
    let(:action) { delete :destroy, params: params }

    it 'destroys' do
      expect { action }.to change(CalendarEventParticipant, :count).by(-1)
      expect(response).to have_http_status(:success)
    end

    it 'incorrect id' do
      delete :destroy, format: :json, params: { calendar_event_id: calendar_event.id, id: -1 }
      expect(response).to have_http_status(:not_found)
    end
  end

end
