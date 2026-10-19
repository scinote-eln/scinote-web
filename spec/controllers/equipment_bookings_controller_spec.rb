# frozen_string_literal: true

require 'rails_helper'

describe EquipmentBookingsController, type: :controller do
  include_context 'without compiled assets'
  login_user
  render_views

  let(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, team: team, created_by: user }
  let(:enabled) { true }

  before do
    user.update!(current_team_id: team.id)
    allow(Repository).to receive(:equipment_booking_enabled?).and_return(enabled)
  end

  describe 'GET index' do
    it 'renders the index page with breadcrumbs when enabled' do
      get :index

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(assigns(:breadcrumbs_items)).to eq([{ label: I18n.t('breadcrumbs.equipment_bookings'), url: nil }])
    end

    context 'when equipment booking is disabled' do
      let(:enabled) { false }

      it 'renders the promo page' do
        get :index

        expect(response).to render_template(:promo)
      end
    end
  end

  describe 'GET assigned_repository_rows' do
    let(:body) { JSON.parse(response.body) }
    let!(:row_b) { create :repository_row, repository: repository, name: 'beta row', created_by: user }
    let!(:row_a) { create :repository_row, repository: repository, name: 'Alpha row', created_by: user }
    let!(:archived_row) { create :repository_row, :archived, repository: repository, name: 'archived row', created_by: user }

    it 'returns active rows ordered by name case-insensitively' do
      get :assigned_repository_rows, params: { repository_id: repository.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(body['paginated']).to be(true)
      expect(body['data']).to eq([[row_a.id, 'Alpha row'], [row_b.id, 'beta row']])
    end

    it 'filters rows by query' do
      get :assigned_repository_rows, params: { repository_id: repository.id, query: 'beta' }, format: :json

      expect(body['data']).to eq([[row_b.id, 'beta row']])
    end

    it 'returns 404 for an unknown repository' do
      get :assigned_repository_rows, params: { repository_id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 when the user cannot read the repository' do
      without_partial_double_verification do
        allow(controller).to receive(:can_read_repository?).and_return(false)
      end

      get :assigned_repository_rows, params: { repository_id: repository.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end

    context 'when equipment booking is disabled' do
      let(:enabled) { false }

      it 'renders the promo template instead of data' do
        get :assigned_repository_rows, params: { repository_id: repository.id }

        expect(response).to render_template(:promo)
      end
    end
  end

  describe 'GET assigned_users' do
    let(:body) { JSON.parse(response.body) }
    let(:booker) { create :user, full_name: 'Booker Person' }
    let(:row) { create :repository_row, repository: repository, created_by: user }
    let(:archived_row) { create :repository_row, :archived, repository: repository, created_by: user }

    before do
      event = create :calendar_event, team: team, subject: row, created_by: user
      CalendarEventParticipant.create!(calendar_event: event, user: booker)
    end

    def ids
      body['data'].map(&:first)
    end

    it 'returns repository users and users assigned to events by default' do
      get :assigned_users, params: { repository_id: repository.id }, format: :json

      expect(response).to have_http_status(:ok)
      expect(ids).to contain_exactly(user.id, booker.id)
      entry = body['data'].find { |u| u.first == booker.id }
      expect(entry[1]).to eq(booker.name)
      expect(entry[2]).to have_key('avatar_url')
    end

    it 'returns only repository users in repository_only mode' do
      get :assigned_users, params: { repository_id: repository.id, mode: 'repository_only' }, format: :json

      expect(ids).to eq([user.id])
    end

    it 'returns only users assigned to events in assigned_only mode' do
      get :assigned_users, params: { repository_id: repository.id, mode: 'assigned_only' }, format: :json

      expect(ids).to eq([booker.id])
    end

    it 'ignores events on archived rows' do
      archived_event = create :calendar_event, team: team, subject: archived_row, created_by: user
      other = create :user
      CalendarEventParticipant.create!(calendar_event: archived_event, user: other)

      get :assigned_users, params: { repository_id: repository.id, mode: 'assigned_only' }, format: :json

      expect(ids).not_to include(other.id)
    end

    it 'filters users by query' do
      get :assigned_users, params: { repository_id: repository.id, query: 'Booker Person' }, format: :json

      expect(ids).to eq([booker.id])
    end

    it 'returns 404 for an unknown repository' do
      get :assigned_users, params: { repository_id: -1 }, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 403 when the user cannot read the repository' do
      without_partial_double_verification do
        allow(controller).to receive(:can_read_repository?).and_return(false)
      end

      get :assigned_users, params: { repository_id: repository.id }, format: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
