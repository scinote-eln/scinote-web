# frozen_string_literal: true

require 'rails_helper'

describe NavigationsController, type: :controller do
  login_user

  let(:user) { subject.current_user }
  let!(:team) { create :team, created_by: user }

  before { user.update!(current_team_id: team.id) }

  describe 'GET top_menu' do
    let(:body) { JSON.parse(response.body) }

    it 'returns the menu structure for the current user' do
      get :top_menu, format: :json

      expect(response).to have_http_status(:ok)
      expect(body['root_url']).to eq('/')
      expect(body['current_team']).to eq(team.id)
      expect(body['teams']).to include([team.id, team.name])
      expect(body['user']).to include('name' => user.full_name, 'sign_out_url' => destroy_user_session_path)
      expect(body['help_menu'].map { |l| l['url'] }).to include(Constants::SUPPORT_URL, Constants::TUTORIALS_URL)
      expect(body['user_menu'].map { |l| l['url'] }).to include(edit_user_registration_path, preferences_path)
      expect(body['unseen_notifications_count']).to eq(0)
    end

    it 'lists teams ordered by name' do
      team.update!(name: 'Mmm team')
      other = create :team, name: 'Aaa team', created_by: user

      get :top_menu, format: :json

      expect(body['teams'].map(&:last)).to eq(['Aaa team', 'Mmm team'])
    end

    it 'includes team management links when user can manage the team' do
      get :top_menu, format: :json

      urls = body['settings_menu'].map { |l| l['url'] }
      expect(urls).to include(teams_path, automations_team_path(team), users_settings_team_user_groups_path(team), addons_path)
    end

    it 'omits team management links when user cannot manage the team' do
      without_partial_double_verification do
        allow(controller).to receive(:can_manage_team?).and_return(false)
      end

      get :top_menu, format: :json

      urls = body['settings_menu'].map { |l| l['url'] }
      expect(urls).to include(teams_path, addons_path)
      expect(urls).not_to include(automations_team_path(team))
    end

    it 'adds the webhooks link when the user can create activity filters' do
      without_partial_double_verification do
        allow(controller).to receive(:can_create_acitivity_filters?).and_return(true)
      end

      get :top_menu, format: :json

      expect(body['settings_menu'].last['url']).to eq(users_settings_webhooks_path)
    end

    it 'counts unseen in-app notifications' do
      create :notification, type: 'DeliveryNotification', recipient_id: user.id, read_at: nil
      create :notification, type: 'DeliveryNotification', recipient_id: user.id, read_at: nil, params: { hide_in_app: true }
      create :notification, type: 'DeliveryNotification', recipient_id: user.id, read_at: Time.current

      get :top_menu, format: :json

      expect(body['unseen_notifications_count']).to eq(1)
    end
  end

  describe 'POST navigator_state' do
    def state
      user.user_settings.find_by(key: 'navigator_state')&.value
    end

    it 'stores collapsed state and width' do
      expect { post :navigator_state, params: { state: 'collapsed', width: '321' } }
        .to change { user.user_settings.where(key: 'navigator_state').count }.by(1)

      expect(state).to include('collapsed' => true, 'width' => 321)
    end

    it 'stores expanded state and keeps previous width when width is not positive' do
      post :navigator_state, params: { state: 'collapsed', width: '300' }
      post :navigator_state, params: { state: 'expanded', width: '0' }

      expect(state).to include('collapsed' => false, 'width' => 300)
    end
  end
end
