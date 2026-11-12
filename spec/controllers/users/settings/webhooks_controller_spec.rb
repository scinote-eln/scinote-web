# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::WebhooksController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let(:json) { JSON.parse(response.body) }
  let!(:filter) { create :activity_filter, name: 'Middle filter' }
  let!(:webhook) { create :webhook, activity_filter: filter, url: 'https://old.example.com' }

  around do |example|
    original = Rails.application.config.x.webhooks_enabled
    Rails.application.config.x.webhooks_enabled = true
    example.run
    Rails.application.config.x.webhooks_enabled = original
  end

  describe 'when activity filters are disabled' do
    # Set after the let! records are created, because the Webhook model validates the flag.
    before { Rails.application.config.x.webhooks_enabled = false }

    it 'forbids the index page' do
      get :index
      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids creating a webhook' do
      expect { post :create, params: { filter_id: filter.id, webhook: { url: 'https://a.example.com' } } }
        .not_to change(Webhook, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET index' do
    let!(:alpha_filter) { create :activity_filter, name: 'Alpha filter' }
    let!(:zulu_filter) { create :activity_filter, name: 'Zulu filter' }

    it 'lists filters sorted from A to Z by default' do
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:activity_filters).map(&:name)).to eq ['Alpha filter', 'Middle filter', 'Zulu filter']
    end

    it 'lists filters sorted from Z to A for the ztoa sort' do
      get :index, params: { sort: 'ztoa' }
      expect(assigns(:activity_filters).map(&:name)).to eq ['Zulu filter', 'Middle filter', 'Alpha filter']
      expect(assigns(:current_sort)).to eq 'ztoa'
    end
  end

  describe 'POST create' do
    let(:webhook_params) do
      { http_method: 'post', url: 'https://hooks.example.com/notify', active: 'true',
        secret_key: 'sekret', include_serialized_subject: 'true' }
    end

    it 'creates a webhook for the filter and redirects with a flash' do
      expect { post :create, params: { filter_id: filter.id, webhook: webhook_params } }
        .to change { filter.webhooks.count }.by(1)

      created = filter.webhooks.order(:id).last
      expect(created.url).to eq 'https://hooks.example.com/notify'
      expect(created.secret_key).to eq 'sekret'
      expect(created.include_serialized_subject).to be true
      expect(response).to redirect_to(users_settings_webhooks_path(sort: 'atoz'))
      expect(flash[:success]).to eq I18n.t('webhooks.index.webhook_created')
    end

    it 'keeps the sort in the redirect' do
      post :create, params: { filter_id: filter.id, webhook: webhook_params, sort: 'ztoa' }
      expect(response).to redirect_to(users_settings_webhooks_path(sort: 'ztoa'))
    end

    it 'returns validation errors as json for an invalid url' do
      expect do
        post :create, params: { filter_id: filter.id, webhook: webhook_params.merge(url: 'not a url') }
      end.not_to change(Webhook, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to have_key('url')
    end

    it 'returns not found when the filter does not exist' do
      expect { post :create, params: { filter_id: 0, webhook: webhook_params }, format: :json }
        .not_to change(Webhook, :count)
      expect(response).to have_http_status(:not_found)
    end

    it 'returns validation errors for an unknown http method' do
      pending 'bug: invalid http_method should return validation errors instead of raising'
      expect { post :create, params: { filter_id: filter.id, webhook: webhook_params.merge(http_method: 'put') } }
        .not_to change(Webhook, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PUT update' do
    it 'updates the webhook and redirects with a flash' do
      put :update, params: { filter_id: filter.id, id: webhook.id, webhook: { url: 'https://new.example.com' } }
      expect(webhook.reload.url).to eq 'https://new.example.com'
      expect(response).to redirect_to(users_settings_webhooks_path(sort: 'atoz'))
      expect(flash[:success]).to eq I18n.t('webhooks.index.webhook_updated')
    end

    it 'returns validation errors as json and keeps the old url' do
      put :update, params: { filter_id: filter.id, id: webhook.id, webhook: { url: 'broken' } }, format: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors']).to have_key('url')
      expect(webhook.reload.url).to eq 'https://old.example.com'
    end

    it 'returns not found for an unknown webhook' do
      put :update, params: { filter_id: filter.id, id: 0, webhook: { url: 'https://new.example.com' } }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE destroy' do
    it 'destroys the webhook and redirects with a flash' do
      expect { delete :destroy, params: { filter_id: filter.id, id: webhook.id } }
        .to change(Webhook, :count).by(-1)
      expect(response).to redirect_to(users_settings_webhooks_path(sort: 'atoz'))
      expect(flash[:success]).to eq I18n.t('webhooks.index.webhook_deleted')
    end

    it 'returns not found for an unknown webhook' do
      expect { delete :destroy, params: { filter_id: filter.id, id: 0 }, format: :json }
        .not_to change(Webhook, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST destroy_filter' do
    it 'destroys the filter together with its webhooks' do
      expect { post :destroy_filter, params: { filter_id: filter.id } }
        .to change(ActivityFilter, :count).by(-1)
        .and change(Webhook, :count).by(-1)
      expect(response).to redirect_to(users_settings_webhooks_path(sort: 'atoz'))
    end

    it 'returns not found for an unknown filter' do
      expect { post :destroy_filter, params: { filter_id: 0 }, format: :json }
        .not_to change(ActivityFilter, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET filter_info' do
    let(:team) { create :team, created_by: user }

    it 'describes teams, users, activity types, period and subjects of the filter' do
      type_name, type_value = Activity.type_ofs.first
      filter.update!(filter: {
                       'teams' => [team.id.to_s],
                       'users' => [user.id.to_s],
                       'types' => [type_value.to_s],
                       'from_date' => '2024-01-02',
                       'to_date' => '2024-02-03',
                       'subjects' => { 'Team' => [team.id.to_s] }
                     })

      get :filter_info, params: { filter_id: filter.id }, format: :json

      expect(response).to have_http_status(:success)
      expect(json['filter_elements']).to eq [
        team.name,
        user.full_name,
        I18n.t("global_activities.activity_name.#{type_name}"),
        "#{I18n.t('global_activities.index.period_label')} 2024-02-03 - 2024-01-02",
        team.name
      ]
    end

    it 'returns an empty list for a filter without elements' do
      filter.update!(filter: { 'types' => [] })
      get :filter_info, params: { filter_id: filter.id }, format: :json
      expect(json['filter_elements']).to eq []
    end

    it 'returns not found for an unknown filter' do
      get :filter_info, params: { filter_id: 0 }, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
