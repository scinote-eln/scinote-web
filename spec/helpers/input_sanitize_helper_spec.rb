# frozen_string_literal: true

require 'rails_helper'

describe InputSanitizeHelper, type: :helper do
  let(:user) { create(:user) }

  around do |example|
    original = Rails.application.config.x.custom_sanitizer_config
    example.run
  ensure
    Rails.application.config.x.custom_sanitizer_config = original
  end

  describe '#sanitize_input' do
    it 'removes script markup and keeps the safe text' do
      result = helper.sanitize_input('ok<script>alert(1)</script>')

      expect(result).to include 'ok'
      expect(result).not_to include '<script'
      expect(result).not_to include 'alert(1)'
    end

    it 'returns an html safe string' do
      expect(helper.sanitize_input('<b>text</b>')).to be_html_safe
    end

    it 'uses the sanitizer config passed as an argument' do
      expect(helper.sanitize_input('<b>x</b><i>y</i>', sanitizer_config: { elements: ['i'] }))
        .to eq 'x<i>y</i>'
    end

    it 'uses the custom sanitizer config from the application when it is set' do
      Rails.application.config.x.custom_sanitizer_config = { elements: ['b'] }

      expect(helper.sanitize_input('<b>x</b><i>y</i>', sanitizer_config: { elements: ['i'] }))
        .to eq '<b>x</b>y'
    end
  end

  describe '#escape_input' do
    it 'escapes html special characters' do
      expect(helper.escape_input('<b>&</b>')).to eq '&lt;b&gt;&amp;&lt;/b&gt;'
    end
  end

  describe '#unescape_input' do
    it 'turns escaped html entities back into characters' do
      expect(helper.unescape_input('&lt;b&gt; &amp; &quot;')).to eq '<b> & "'
    end
  end

  describe '#smart_annotation_text' do
    it 'replaces a user annotation with the user name' do
      text = "hello [@#{user.full_name}~#{user.id.base62_encode}]"

      result = helper.smart_annotation_text(text)

      expect(result).to include user.full_name
      expect(result).not_to include '[@'
    end

    it 'sanitizes the text by default' do
      expect(helper.smart_annotation_text('plain<script>x</script>')).not_to include '<script'
    end

    it 'keeps the text unsanitized when sanitize_text is false' do
      expect(helper.smart_annotation_text('<script>x</script>', sanitize_text: false))
        .to eq '<script>x</script>'
    end
  end

  describe '#custom_auto_link' do
    it 'turns urls into links that open in a new tab' do
      result = helper.custom_auto_link('see https://example.com')

      expect(result).to include 'href="https://example.com"'
      expect(result).to include 'target="_blank"'
    end
  end
end
