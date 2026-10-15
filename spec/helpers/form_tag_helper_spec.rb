# frozen_string_literal: true

require 'rails_helper'

describe FormTagHelper, type: :helper do
  describe '#recaptcha_input_tag' do
    around do |example|
      original = Rails.configuration.x.enable_recaptcha
      example.run
    ensure
      Rails.configuration.x.enable_recaptcha = original
    end

    before do
      allow(helper).to receive(:recaptcha_tags).with(nonce: 'abc').and_return('<div id="captcha"></div>'.html_safe)
      allow(helper).to receive(:content_security_policy_nonce).and_return('abc')
    end

    it 'returns nil when recaptcha is disabled' do
      Rails.configuration.x.enable_recaptcha = false

      expect(helper.recaptcha_input_tag).to be_nil
    end

    context 'when recaptcha is enabled' do
      before { Rails.configuration.x.enable_recaptcha = true }

      it 'renders the label and the recaptcha widget' do
        html = helper.recaptcha_input_tag

        expect(html).to be_html_safe
        expect(html).to include("<div class='form-group sci-input-container'>")
        expect(html).to include(I18n.t('users.registrations.new.captcha_description'))
        expect(html).to include('<div id="captcha"></div>')
        expect(html).not_to include('help-block')
      end

      it 'omits the description when asked to' do
        html = helper.recaptcha_input_tag(include_description: false)

        expect(html).not_to include('recaptcha_label')
        expect(html).to include('<div id="captcha"></div>')
      end

      it 'renders the error message and error class from the flash' do
        helper.flash[:recaptcha_error] = 'Captcha failed'

        html = helper.recaptcha_input_tag

        expect(html).to include("sci-input-containerhas-error'")
        expect(html).to include("<span class='help-block'>Captcha failed</span>")
      end
    end
  end
end
