# frozen_string_literal: true

require 'rails_helper'

describe GlobalConstantsController, type: :controller do
  render_views

  describe 'GET index' do
    let(:constants) do
      body = response.body
      JSON.parse(body[/\Aconst GLOBAL_CONSTANTS = (.*);\s*\z/m, 1])
    end

    context 'without a signed in user' do
      it 'renders the constants javascript' do
        get :index, format: :js, xhr: true

        expect(response).to have_http_status(:ok)
        expect(response.body).to start_with('const GLOBAL_CONSTANTS = ')
      end
    end

    context 'with a signed in user' do
      login_user

      it 'exposes the configured constants' do
        get :index, format: :js, xhr: true

        expect(constants).to include(
          'NAME_MAX_LENGTH' => Constants::NAME_MAX_LENGTH,
          'NAME_MIN_LENGTH' => Constants::NAME_MIN_LENGTH,
          'TEXT_MAX_LENGTH' => Constants::TEXT_MAX_LENGTH,
          'SEARCH_LIMIT' => Constants::SEARCH_LIMIT,
          'FILE_MAX_SIZE_MB' => Rails.configuration.x.file_max_size_mb,
          'TABLE_CARD_MIN_WIDTH' => 340,
          'TABLE_CARD_GAP' => 16,
          'HAS_UNSAVED_DATA_CLASS_NAME' => 'has-unsaved-data'
        )
      end

      it 'exposes the report header and footer limits' do
        get :index, format: :js, xhr: true

        expect(constants).to include(
          'MY_MODULE_REPORT_HEADER_MAX_LENGTH' => Constants::MY_MODULE_REPORT_HEADER_MAX_LENGTH,
          'MY_MODULE_REPORT_FOOTER_MAX_LENGTH' => Constants::MY_MODULE_REPORT_FOOTER_MAX_LENGTH
        )
      end
    end
  end
end
