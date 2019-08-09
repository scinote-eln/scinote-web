# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProtocolImporters::ProtocolDescriptionBuilder do
  let(:description_only) do
    JSON.parse(file_fixture('protocol_importers/description_with_body.json').read).to_h.with_indifferent_access
  end
  let(:description_with_image) do
    JSON.parse(file_fixture('protocol_importers/description_with_image.json').read).to_h.with_indifferent_access
  end
  let(:description_with_extra_content) do
    JSON.parse(file_fixture('protocol_importers/description_with_extra_content.json').read).to_h.with_indifferent_access
  end
  let(:description_with_html) do
    JSON.parse(file_fixture('protocol_importers/description_with_body_html.json').read).to_h.with_indifferent_access
  end

  describe 'self.generate' do
    context 'when description field not exists' do
      it 'returns empty string' do
        expect(described_class.generate({})).to be == ''
      end
    end

    context 'when have only description' do
      it 'includes paragraph description' do
        expect(described_class.generate(description_only)).to include('<p> original desc </p>')
      end

      it 'strips HTML tags' do
        expect(described_class.generate(description_with_html).scan('script').count).to be == 0
      end
    end

    context 'when includes image' do
      it 'includes image tag' do
        expect(described_class.generate(description_with_image)).to include('<img src=')
      end
    end

    context 'when have extra content' do
      it 'add extra fields as paragraphs' do
        expect(described_class.generate(description_with_extra_content).scan('<br/>').size).to be == 10
      end
    end
  end
end
