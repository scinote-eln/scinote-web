# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolsIO::V3::ApiClient do
  CONSTANTS = Constants::PROTOCOLS_IO_V3_API
  TOKEN = 'test_token'

  describe '#protocol_list' do
    URL = "#{CONSTANTS[:base_uri]}protocols"

    let(:stub_protocols) do
      stub_request(:get, URL).with(query: hash_including({}))
                             .to_return(status: 200,
                                        body: JSON.generate(status_code: 0),
                                        headers: { 'Content-Type': 'application/json' })
    end

    let(:default_query_params) do
      CONSTANTS.dig(:endpoints, :protocols, :default_query_params)
    end

    it 'returns 200 on successfull call' do
      stub_protocols
      expect(subject.protocol_list.code).to eq 200
      expect(stub_protocols).to have_been_requested
    end

    it 'raises NetworkError on timeout' do
      stub_request(:get, URL).with(query: hash_including({})).to_timeout

      expect { subject.protocol_list }.to raise_error(ProtocolImporters::ProtocolsIO::V3::NetworkError)
    end

    it 'raises ArgumentError when status_code = 1' do
      stub_request(:get, URL).with(query: hash_including({}))
                             .to_return(status: 200,
                                        body: JSON.generate(status_code: 1, error_message: 'Argument error'),
                                        headers: { 'Content-Type': 'application/json' })

      expect { subject.protocol_list }.to raise_error(ProtocolImporters::ProtocolsIO::V3::ArgumentError)
    end

    it 'raises UnauthorizedError when status_code = 1218' do
      stub_request(:get, URL).with(query: hash_including({}))
                             .to_return(status: 200,
                                        body: JSON.generate(status_code: 1218, error_message: 'Argument error'),
                                        headers: { 'Content-Type': 'application/json' })

      expect { subject.protocol_list }.to raise_error(ProtocolImporters::ProtocolsIO::V3::UnauthorizedError)
    end

    it 'raises UnauthorizedError when status_code = 1219' do
      stub_request(:get, URL).with(query: hash_including({}))
                             .to_return(status: 200,
                                        body: JSON.generate(status_code: 1219, error_message: 'Argument error'),
                                        headers: { 'Content-Type': 'application/json' })

      expect { subject.protocol_list }.to raise_error(ProtocolImporters::ProtocolsIO::V3::UnauthorizedError)
    end

    it 'requests server with default query parameters if none are given' do
      stub_protocols.with(query: default_query_params)

      subject.protocol_list
      expect(WebMock).to have_requested(:get, URL).with(query: default_query_params)
    end

    it 'requests server with given query parameters' do
      query = {
        filter: :user_public,
        key: 'banana',
        order_dir: :asc,
        order_field: :date,
        page_id: 2,
        page_size: 15,
        fields: 'somefields'
      }
      stub_protocols.with(query: query)

      subject.protocol_list(query)
      expect(WebMock).to have_requested(:get, URL).with(query: query)
    end

    it 'should send authorization token if provided on initialization' do
      headers = { 'Authorization': "Bearer #{TOKEN}" }
      stub_request(:get, URL).with(headers: headers, query: default_query_params)
                             .to_return(status: 200,
                                        body: JSON.generate(status_code: 0),
                                        headers: { 'Content-Type': 'application/json' })

      ProtocolImporters::ProtocolsIO::V3::ApiClient.new(TOKEN).protocol_list
      expect(WebMock).to have_requested(:get, URL).with(headers: headers, query: default_query_params)
    end
  end

  describe '#single_protocol' do
    PROTOCOL_ID = 15
    SINGLE_PROTOCOL_URL = "#{CONSTANTS[:base_uri]}protocols/#{PROTOCOL_ID}"

    let(:stub_single_protocol) do
      stub_request(:get, SINGLE_PROTOCOL_URL).to_return(
        status: 200,
        body: JSON.generate(status_code: 0),
        headers: { 'Content-Type': 'application/json' }
      )
    end

    it 'returns 200 on successfull call' do
      stub_single_protocol

      expect(subject.single_protocol(PROTOCOL_ID).code).to eq 200
      expect(stub_single_protocol).to have_been_requested
    end

    it 'raises NetworkError on timeout' do
      stub_request(:get, SINGLE_PROTOCOL_URL).to_timeout

      expect { subject.single_protocol(PROTOCOL_ID) }.to raise_error(ProtocolImporters::ProtocolsIO::V3::NetworkError)
    end

    it 'should send authorization token if provided on initialization' do
      headers = { 'Authorization': "Bearer #{TOKEN}" }
      stub_single_protocol.with(headers: headers)

      ProtocolImporters::ProtocolsIO::V3::ApiClient.new(TOKEN).single_protocol(PROTOCOL_ID)
      expect(WebMock).to have_requested(:get, SINGLE_PROTOCOL_URL).with(headers: headers)
    end
  end

  describe '#protocol_html_preview' do
    PROTOCOL_URI = 'Extracting-DNA-from-bananas-esvbee6'

    let(:stub_html_preview) do
      stub_request(:get, "https://www.protocols.io/view/#{PROTOCOL_URI}.html")
    end

    it 'returns 200 on successfull call' do
      stub_html_preview.to_return(status: 200, body: '[]', headers: {})

      expect(subject.protocol_html_preview(PROTOCOL_URI).code).to eq 200
      expect(stub_html_preview).to have_been_requested
    end

    it 'raises NetworkErrorr on timeout' do
      stub_html_preview.to_timeout

      expect { subject.protocol_html_preview(PROTOCOL_URI) }
        .to raise_error(ProtocolImporters::ProtocolsIO::V3::NetworkError)
    end
  end
end
