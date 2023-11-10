# frozen_string_literal: true

require 'rails_helper'

describe ProtocolImporters::ProtocolsIo::V3::ApiClient do
  CONSTANTS = Constants::PROTOCOLS_IO_V3_API

  describe '#protocol_list' do
    context 'when search key is not given' do
      URL_PUBLICATIONS = "#{CONSTANTS[:base_uri]}publications"

      let(:query_params) do
        { latest: '20' }
      end

      let(:stub_protocols) do
        stub_request(:get, URL_PUBLICATIONS)
          .with(query: query_params)
          .to_return(status: 200,
                     body: JSON.generate(status_code: 0),
                     headers: { 'Content-Type': 'application/json' })
      end

      it 'requests "publications" URL with latest=50 when no query params are given' do
        stub_protocols
        subject.protocol_list
        expect(WebMock).to have_requested(:get, URL_PUBLICATIONS)
          .with(query: query_params)
      end
    end

    context 'when search key is given' do
      URL = "#{CONSTANTS[:base_uri]}protocols"

      let(:key_query) do
        { key: 'key' }.stringify_keys
      end

      let(:default_query_params_with_key) do
        CONSTANTS.dig(:endpoints, :protocols, :default_query_params).merge(key_query)
      end

      let(:stub_protocols) do
        stub_request(:get, URL).with(query: default_query_params_with_key)
      end

      let(:protocol_list_call) do
        subject.protocol_list(key_query)
      end

      it 'returns 200 on successfull call' do
        stub_protocols.to_return(status: 200,
                                 body: JSON.generate(status_code: 0),
                                 headers: { 'Content-Type': 'application/json' })
        expect(protocol_list_call.code).to eq 200
        expect(stub_protocols).to have_been_requested
      end

      it 'raises NetworkError on timeout' do
        stub_protocols.to_timeout

        expect { protocol_list_call }.to raise_error(ProtocolImporters::ProtocolsIo::V3::NetworkError)
      end

      it 'raises ArgumentError when status_code = 1' do
        stub_protocols.to_return(status: 200,
                                 body: JSON.generate(status_code: 1, error_message: 'Argument error'),
                                 headers: { 'Content-Type': 'application/json' })

        expect { protocol_list_call }.to raise_error(ProtocolImporters::ProtocolsIo::V3::ArgumentError)
      end

      it 'raises UnauthorizedError when status_code = 1218' do
        stub_protocols.to_return(status: 200,
                                 body: JSON.generate(status_code: 1218, error_message: 'Argument error'),
                                 headers: { 'Content-Type': 'application/json' })

        expect { protocol_list_call }.to raise_error(ProtocolImporters::ProtocolsIo::V3::UnauthorizedError)
      end

      it 'raises UnauthorizedError when status_code = 1219' do
        stub_protocols.to_return(status: 200,
                    body: JSON.generate(status_code: 1219, error_message: 'Argument error'),
                    headers: { 'Content-Type': 'application/json' })

        expect { protocol_list_call }.to raise_error(ProtocolImporters::ProtocolsIo::V3::UnauthorizedError)
      end

      it 'requests server with default query parameters if none are given' do
        stub_protocols.to_return(status: 200,
                                 body: JSON.generate(status_code: 0),
                                 headers: { 'Content-Type': 'application/json' })

        subject.protocol_list(key_query)
        expect(WebMock).to have_requested(:get, URL).with(query: default_query_params_with_key)
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
                      .to_return(status: 200,
                                body: JSON.generate(status_code: 0),
                                headers: { 'Content-Type': 'application/json' })

        subject.protocol_list(query)
        expect(WebMock).to have_requested(:get, URL).with(query: query)
      end
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

      expect { subject.single_protocol(PROTOCOL_ID) }.to raise_error(ProtocolImporters::ProtocolsIo::V3::NetworkError)
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
        .to raise_error(ProtocolImporters::ProtocolsIo::V3::NetworkError)
    end
  end
end
