# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProtocolImporters::AttachmentsBuilder do
  let(:step) do
    JSON.parse(file_fixture('protocol_importers/step_with_attachments.json').read).to_h.with_indifferent_access
  end
  let(:generate_files_from_step) { described_class.generate(step) }
  let(:first_file_in_result) { generate_files_from_step.first }
  let(:generate_json_files_from_step) { described_class.generate_json(step) }

  before do
    stub_request(:get, 'https://pbs.twimg.com/media/Cwu3zrZWQAA7axs.jpg').to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'http://something.com/wp-content/uploads/2014/11/14506718045_5b3e71dacd_o.jpg')
      .to_return(status: 200, body: '', headers: {})
  end

  describe 'self.generate' do
    it 'returns array of Asset instances' do
      expect(first_file_in_result).to be_instance_of(Asset)
    end

    it 'returns valid table' do
      expect(first_file_in_result).to be_valid
    end
  end

  describe 'self.generate_json' do
    it 'returns JSON with 2 items (files)' do
      expect(generate_json_files_from_step.size).to be == 2
    end

    it 'returns JSON item with name and url' do
      expect(generate_json_files_from_step.first.keys).to contain_exactly(:name, :url)
    end
  end
end
