# frozen_string_literal: true

require 'rails_helper'

describe ActiveStorage::Service::CustomS3Service do
  def build_service(**extra)
    described_class.new(
      bucket: 'test-bucket', region: 'us-east-1', stub_responses: true,
      access_key_id: 'AKIATEST', secret_access_key: 'secret', **extra
    )
  end

  let(:service) { build_service(subfolder: 'sub') }
  let(:client) { service.bucket.client }

  it 'is an ActiveStorage S3 service' do
    expect(service).to be_a(ActiveStorage::Service::S3Service)
  end

  describe '#initialize' do
    it 'stores the subfolder and does not pass it to the AWS client' do
      expect(service.subfolder).to eq 'sub'
      expect(service.bucket.name).to eq 'test-bucket'
    end

    it 'has no subfolder when not configured' do
      expect(build_service.subfolder).to be_nil
    end
  end

  describe '#object_for (private)' do
    it 'prefixes the key with the subfolder' do
      expect(service.send(:object_for, 'abc').key).to eq 'sub/abc'
    end

    it 'leaves the key untouched without subfolder' do
      expect(build_service.send(:object_for, 'abc').key).to eq 'abc'
    end

    it 'leaves the key untouched when subfolder is blank' do
      expect(build_service(subfolder: '').send(:object_for, 'abc').key).to eq 'abc'
    end
  end

  describe 'object operations' do
    it 'deletes objects under the subfolder' do
      service.delete('key1')
      request = client.api_requests.find { |r| r[:operation_name] == :delete_object }
      expect(request[:params]).to include(bucket: 'test-bucket', key: 'sub/key1')
    end

    it 'uploads a small file to the prefixed key' do
      service.upload('key2', StringIO.new('hello'), checksum: nil, content_type: 'text/plain')
      request = client.api_requests.find { |r| r[:operation_name] == :put_object }
      expect(request[:params]).to include(bucket: 'test-bucket', key: 'sub/key2')
    end
  end

  describe '#upload_stream (private)' do
    context 'without transfer manager' do
      before { service.instance_variable_set(:@transfer_manager, nil) }

      it 'delegates to the prefixed object' do
        object = double('s3_object')
        allow(service).to receive(:object_for).with('k').and_return(object)
        received = nil
        allow(object).to receive(:upload_stream) do |**opts, &block|
          received = opts
          block.call(:out)
        end

        yielded = nil
        service.send(:upload_stream, key: 'k', content_type: 'text/plain') { |out| yielded = out }
        expect(received).to eq(content_type: 'text/plain')
        expect(yielded).to eq :out
      end
    end

    context 'with transfer manager' do
      let(:manager) { double('transfer_manager') }

      before { service.instance_variable_set(:@transfer_manager, manager) }

      it 'prefixes the key with the subfolder' do
        expect(manager).to receive(:upload_stream)
          .with(key: 'sub/k', bucket: 'test-bucket', content_type: 'text/plain')
        service.send(:upload_stream, key: 'k', content_type: 'text/plain') { |_out| nil }
      end

      it 'keeps the key without subfolder' do
        plain = build_service
        plain.instance_variable_set(:@transfer_manager, manager)
        expect(manager).to receive(:upload_stream).with(key: 'k', bucket: 'test-bucket')
        plain.send(:upload_stream, key: 'k') { |_out| nil }
      end
    end
  end

  describe '#delete_prefixed' do
    let(:objects) { instance_double(Aws::S3::ObjectSummary::Collection, batch_delete!: true) }

    it 'deletes objects below the subfolder-prefixed prefix' do
      expect(service.bucket).to receive(:objects).with(prefix: 'sub/folder/').and_return(objects)
      expect(objects).to receive(:batch_delete!)
      service.delete_prefixed('folder/')
    end

    it 'uses the plain prefix without subfolder' do
      plain = build_service
      expect(plain.bucket).to receive(:objects).with(prefix: 'folder/').and_return(objects)
      plain.delete_prefixed('folder/')
    end
  end
end
