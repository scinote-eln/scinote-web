# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::Account::ConnectedAccountsController, type: :controller do
  login_user

  let(:user) { subject.current_user }

  describe 'GET index' do
    it 'lists the providers linked to the user' do
      create :user_identity, user: user, provider: 'okta'
      create :user_identity, user: user, provider: 'saml'
      create :user_identity, provider: 'azure_ad'

      get :index

      expect(response).to have_http_status(:success)
      expect(assigns(:linked_accounts)).to match_array %w(okta saml)
    end

    it 'lists no providers when nothing is linked' do
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:linked_accounts)).to eq []
    end
  end

  describe 'DELETE destroy' do
    let!(:identity) { create :user_identity, user: user, provider: 'okta' }

    it 'unlinks the provider and shows a success flash' do
      expect { delete :destroy, params: { provider: 'okta' } }
        .to change { user.user_identities.count }.by(-1)
      expect(response).to render_template(:index)
      expect(flash[:success]).to eq I18n.t('users.settings.account.connected_accounts.unlink_success')
      expect(assigns(:linked_accounts)).to eq []
    end

    it 'shows an error and keeps other providers when the provider is not linked' do
      create :user_identity, user: user, provider: 'saml'
      expect { delete :destroy, params: { provider: 'github' } }
        .not_to(change { user.user_identities.count })
      expect(flash[:error]).to eq I18n.t('users.settings.account.connected_accounts.errors.not_found')
      expect(assigns(:linked_accounts)).to match_array %w(okta saml)
    end

    it 'shows a generic error and keeps the identity when unlinking fails' do
      allow_any_instance_of(UserIdentity).to receive(:destroy!).and_raise(StandardError, 'db down')
      expect { delete :destroy, params: { provider: 'okta' } }
        .not_to(change { user.user_identities.count })
      expect(response).to render_template(:index)
      expect(flash[:error]).to eq I18n.t('users.settings.account.connected_accounts.errors.generic')
      expect(assigns(:linked_accounts)).to eq ['okta']
    end

    it 'does not touch identities of another user' do
      other_identity = create :user_identity, provider: 'github'
      expect { delete :destroy, params: { provider: 'github' } }
        .not_to(change { UserIdentity.where(id: other_identity.id).count })
      expect(flash[:error]).to eq I18n.t('users.settings.account.connected_accounts.errors.not_found')
    end
  end
end
