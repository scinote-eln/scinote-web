# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::Account::PreferencesController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:json) { JSON.parse(response.body) }

  # Restore the global organization settings whatever an example changed.
  around do |example|
    original_values = ApplicationSettings.instance.values.dup
    persisted = ApplicationSettings.exists?
    begin
      example.run
    ensure
      if persisted
        ApplicationSettings.first.update!(values: original_values)
      else
        ApplicationSettings.delete_all
      end
    end
  end

  def enforce_setting!(key)
    ApplicationSettings.instance.update!(
      values: ApplicationSettings.instance.values.merge(key => true)
    )
  end

  describe 'GET index' do
    it 'renders the preferences page with breadcrumbs' do
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:user)).to eq user
      expect(assigns(:breadcrumbs_items)).to eq [{ label: I18n.t('notifications.breadcrumb'),
                                                   url: preferences_path }]
    end
  end

  describe 'PUT update' do
    it 'updates the time zone of the user' do
      put :update, params: { user: { time_zone: 'Ljubljana' } }, format: :json
      expect(response).to have_http_status(:success)
      expect(json['status']).to eq 'ok'
      expect(user.reload.time_zone).to eq 'Ljubljana'
    end

    it 'updates the date format of the user' do
      new_format = (Constants::SUPPORTED_DATE_FORMATS - [user.date_format]).first
      put :update, params: { user: { date_format: new_format } }, format: :json
      expect(response).to have_http_status(:success)
      expect(user.reload.date_format).to eq new_format
    end

    it 'returns validation errors for an unknown time zone and keeps the old one' do
      old_zone = user.time_zone
      put :update, params: { user: { time_zone: 'Mars/Olympus_Mons' } }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json).to have_key('time_zone')
      expect(user.reload.time_zone).to eq old_zone
    end

    it 'ignores parameters that are not permitted' do
      put :update, params: { user: { job_title: 'Hacker', time_zone: 'Ljubljana' } }, format: :json
      expect(response).to have_http_status(:success)
      expect(user.reload.job_title).to be_nil
      expect(user.reload.time_zone).to eq 'Ljubljana'
    end

    it 'is forbidden to change the time zone when it is enforced by the organization' do
      enforce_setting!('security.time_zone.enforced')
      put :update, params: { user: { time_zone: 'Ljubljana' } }, format: :json
      expect(response).to have_http_status(:forbidden)
      expect(user.reload.time_zone).to eq 'UTC'
    end

    it 'is forbidden to change the date format when it is enforced by the organization' do
      enforce_setting!('security.date_format.enforced')
      old_format = user.date_format
      put :update, params: { user: { date_format: (Constants::SUPPORTED_DATE_FORMATS - [old_format]).first } },
                   format: :json
      expect(response).to have_http_status(:forbidden)
      expect(user.reload.date_format).to eq old_format
    end

    it 'allows the date format when only the time zone is enforced' do
      enforce_setting!('security.time_zone.enforced')
      new_format = (Constants::SUPPORTED_DATE_FORMATS - [user.date_format]).first
      put :update, params: { user: { date_format: new_format } }, format: :json
      expect(response).to have_http_status(:success)
      expect(user.reload.date_format).to eq new_format
    end

    it 'raises when the user parameter is missing' do
      expect { put :update, params: { time_zone: 'Ljubljana' }, format: :json }
        .to raise_error(ActionController::ParameterMissing)
    end

    it 'saves notification settings' do
      pending 'bug: notifications_settings is permitted but User has no writer for it, so the update raises'
      put :update, params: { user: { notifications_settings: { 'comments' => false } } }, format: :json
      expect(response).to have_http_status(:success)
    end
  end
end
