# frozen_string_literal: true

require 'rails_helper'

describe HiddenRepositoryCellRemindersController, type: :controller do
  login_user

  let!(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }
  let!(:repository) { create :repository, created_by: user, team: team }
  let!(:row) { create :repository_row, repository: repository, created_by: user }
  let!(:cell) do
    cell = create :repository_cell, :stock_value, repository_row: row
    cell.value.update_columns(amount: 0, low_stock_threshold: 5)
    cell
  end
  let!(:viewer_role) { UserRole.find_by(name: I18n.t('user_roles.predefined.viewer')) || create(:viewer_role) }
  let(:params) { { repository_id: repository.id, repository_row_id: row.id, repository_cell_id: cell.id } }

  def make_viewer
    UserAssignment.where(user: user, assignable: [team, repository]).update_all(user_role_id: viewer_role.id)
  end

  describe 'POST create' do
    it 'hides the reminder for the current user and returns the remaining count' do
      expect do
        post :create, params: params, format: :json
      end.to change { user.hidden_repository_cell_reminders.count }.by(1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['repository_cell_id']).to eq cell.id
      expect(body['user_id']).to eq user.id
      expect(body['reminder_count']).to eq 0
    end

    it 'reports the reminders that remain visible' do
      date_column = create :repository_column, :date_time_type, repository: repository, created_by: user,
                                                                 metadata: { reminder_value: '1', reminder_unit: '86400' }
      date_cell = create :repository_cell, :date_time_value, repository_row: row, repository_column: date_column
      date_cell.value.update_columns(data: 1.hour.from_now)

      post :create, params: params, format: :json

      expect(JSON.parse(response.body)['reminder_count']).to eq 1
    end

    it 'returns not found for an unknown repository' do
      post :create, params: params.merge(repository_id: 0), format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'returns not found for a row of another repository' do
      other_row = create :repository_row
      post :create, params: params.merge(repository_row_id: other_row.id), format: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'is allowed for a viewer' do
      make_viewer
      expect do
        post :create, params: params, format: :json
      end.to change { user.hidden_repository_cell_reminders.count }.by(1)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create_all' do
    let!(:other_user) { create :user }
    let!(:third_user) { create :user }

    before do
      create_user_assignment(repository, UserRole.find_by(name: I18n.t('user_roles.predefined.owner')),
                             other_user, user)
      create_user_assignment(repository, UserRole.find_by(name: I18n.t('user_roles.predefined.owner')),
                             third_user, user)
      third_user.hidden_repository_cell_reminders.create!(repository_cell_id: cell.id)
    end

    it 'hides the reminder for all repository users that did not hide it yet' do
      expect do
        post :create_all, params: params, format: :json
      end.to change(HiddenRepositoryCellReminder, :count).by(2)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['reminder_count']).to eq 0
      expect(HiddenRepositoryCellReminder.where(repository_cell_id: cell.id).pluck(:user_id))
        .to include(user.id, other_user.id, third_user.id)
    end

    it 'is forbidden for a viewer' do
      make_viewer
      expect do
        post :create_all, params: params, format: :json
      end.not_to change(HiddenRepositoryCellReminder, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
