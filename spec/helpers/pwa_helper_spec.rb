# frozen_string_literal: true

require 'rails_helper'

describe PwaHelper, type: :helper do
  around do |example|
    original = Rails.configuration.x.pwa_domain
    Rails.configuration.x.pwa_domain = 'pwa.example.test'
    example.run
  ensure
    Rails.configuration.x.pwa_domain = original
  end

  describe '#pwa_mobile_app_url' do
    it 'fills every placeholder of the pwa url with the given values' do
      url = helper.pwa_mobile_app_url(11, 22, 33, 44, 55, 66, 'app.example.test')

      expect(url).to eq 'https://pwa.example.test/teams/11/projects/22/experiments/33/tasks/44/protocol/55/66' \
                        '?domain=app.example.test'
    end

    it 'does not change the url template constant' do
      helper.pwa_mobile_app_url(1, 2, 3, 4, 5, 6, 'app.example.test')

      expect(Constants::PWA_URL).to include ':pwa_domain'
      expect(Constants::PWA_URL).to include ':step_id'
    end
  end
end
