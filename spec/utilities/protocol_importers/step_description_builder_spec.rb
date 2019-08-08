# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProtocolImporters::StepDescriptionBuilder do
  let(:description_only) do
    JSON.parse(file_fixture('protocol_importers/description_with_body.json').read).to_h.with_indifferent_access
  end

  let(:description_with_html) do
    JSON.parse(file_fixture('protocol_importers/description_with_body_html.json').read).to_h.with_indifferent_access
  end

  let(:description_with_components) do
    JSON.parse(file_fixture('protocol_importers/step_description_with_components.json').read)
        .to_h.with_indifferent_access
  end

  let(:description_with_extra_content) do
    JSON.parse(file_fixture('protocol_importers/description_with_extra_content.json').read)
        .to_h.with_indifferent_access
  end

  let(:normalized_json) do
    JSON.parse(file_fixture('protocol_importers/normalized_single_protocol.json').read)
        .to_h.with_indifferent_access
  end

  let(:step_description_from_normalized_json) { described_class.generate(normalized_json[:protocol][:steps].first) }

  describe 'self.generate' do
    context 'when description field not exists' do
      it 'returns empty string' do
        expect(described_class.generate({})).to be == ''
      end
    end

    context 'when have only description body' do
      it 'includes paragraph description' do
        expect(described_class.generate(description_only)).to include('<p> original desc')
      end
    end

    context 'when have components' do
      it 'retunrs extra content with title and body' do
        expect(step_description_from_normalized_json.scan('step-description-component-').size).to be == 13
      end

      it 'strips HTML tags from body values for component' do
        expect(described_class.generate(description_with_components).scan('<script>').size).to be == 0
      end
    end

    context 'when have extra_fileds' do
      it 'add extra fields as paragraphs' do
        expect(described_class.generate(description_with_extra_content).scan('<br/>').size).to be == 6
      end

      it 'strips HTML tags for values' do
        expect(described_class.generate(description_with_html).scan('script').count).to be == 0
      end
    end

    context 'when have allowed html tags' do
      it 'does not strip img tags' do
        expect(described_class.generate(description_with_html).scan('img').size).to eq(1)
      end
    end
  end
end
