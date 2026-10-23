# frozen_string_literal: true

require 'rails_helper'

describe Users::Settings::Account::AddonsController, type: :controller do
  login_user

  describe 'GET index' do
    it 'renders the add-ons page with breadcrumbs' do
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:breadcrumbs_items)).to eq [{ label: I18n.t('breadcrumbs.addons'), url: addons_path }]
    end

    it 'reports that no label printer exists when none is configured' do
      get :index
      expect(assigns(:label_printer_any)).to be false
    end

    it 'reports that a label printer exists when one is configured' do
      allow(LabelPrinter).to receive(:any?).and_return(true)
      get :index
      expect(assigns(:label_printer_any)).to be true
    end

    it 'exposes the user agent of the request' do
      request.user_agent = 'RSpec Browser/1.0'
      get :index
      expect(assigns(:user_agent)).to eq 'RSpec Browser/1.0'
    end
  end
end
