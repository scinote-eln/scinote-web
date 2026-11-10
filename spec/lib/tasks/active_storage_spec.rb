# frozen_string_literal: true

require 'rails_helper'

describe 'active_storage:migrate_files' do
  include_context 'rake once'

  let(:tmp_dir) { Dir.mktmpdir }
  let(:service) { double('service') }
  let!(:blob) do
    ActiveStorage::Blob.create!(key: 'rake-old-key', filename: 'a.txt', byte_size: 1, checksum: 'x',
                                content_type: 'text/plain', service_name: 'local')
  end

  around do |example|
    saved = ENV.to_h.slice('PAPERCLIP_STORAGE', 'ACTIVESTORAGE_SERVICE', 'S3_BUCKET', 'S3_SUBFOLDER')
    example.run
  ensure
    %w(PAPERCLIP_STORAGE ACTIVESTORAGE_SERVICE S3_BUCKET S3_SUBFOLDER).each { |k| ENV.delete(k) }
    saved.each { |k, v| ENV[k] = v }
    FileUtils.remove_entry(tmp_dir)
  end

  before do
    %w(PAPERCLIP_STORAGE ACTIVESTORAGE_SERVICE S3_BUCKET S3_SUBFOLDER).each { |k| ENV.delete(k) }
    allow(ActiveStorage::Blob).to receive(:service).and_return(service)
    allow(ActiveStorage::Blob).to receive(:find_each) { |&b| [blob].each(&b) }
  end

  context 'with filesystem storage' do
    before { ENV['PAPERCLIP_STORAGE'] = 'filesystem' }

    it 'moves an existing file to a new unique key' do
      src = Pathname.new(File.join(tmp_dir, 'src'))
      File.write(src, 'data')
      dst = File.join(tmp_dir, 'dst', 'newkey')
      allow(Rails.root).to receive(:join).and_call_original
      allow(Rails.root).to receive(:join).with('public', 'system', 'rake-old-key').and_return(src)
      allow(service).to receive(:path_for) { |_key| dst }

      expect { subject.invoke }.to output(/Moving #{Regexp.escape(src.to_s)} to #{Regexp.escape(dst)}\nFinished\n/).to_stdout

      expect(File.read(dst)).to eq 'data'
      expect(src).not_to exist
      expect(blob.reload.key).not_to eq 'rake-old-key'
    end

    it 'skips blobs whose source file does not exist' do
      expect { subject.invoke }.to output("Finished\n").to_stdout
      expect(blob.reload.key).to eq 'rake-old-key'
    end
  end

  context 'with ACTIVESTORAGE_SERVICE=local' do
    it 'also takes the filesystem branch' do
      ENV['ACTIVESTORAGE_SERVICE'] = 'local'
      expect { subject.invoke }.to output("Finished\n").to_stdout
    end
  end

  context 'with S3 storage' do
    let(:object) { double('object', exists?: true) }
    let(:bucket) { double('bucket', name: 'rake-bucket') }

    before do
      ENV['PAPERCLIP_STORAGE'] = 's3'
      ENV['S3_BUCKET'] = 'rake-bucket'
      resource = instance_double(Aws::S3::Resource)
      allow(Aws::S3::Resource).to receive(:new).and_return(resource)
      allow(resource).to receive(:bucket).with('rake-bucket').and_return(bucket)
      allow(bucket).to receive(:object).and_return(object)
      allow(object).to receive(:move_to)
    end

    it 'moves objects with a known prefix to a new key under the subfolder' do
      blob.update!(key: 'assets/abc')
      ENV['S3_SUBFOLDER'] = 'sub'
      allow(bucket).to receive(:object).with('sub/assets/abc').and_return(object)

      expect { subject.invoke }.to output(%r{Moving sub/assets/abc to sub/\w+\nFinished\n}).to_stdout

      expect(blob.reload.key).not_to eq 'assets/abc'
      expect(object).to have_received(:move_to).with(bucket: 'rake-bucket', key: "sub/#{blob.key}")
    end

    it 'ignores blobs with other key prefixes' do
      expect { subject.invoke }.to output("Finished\n").to_stdout
      expect(object).not_to have_received(:move_to)
    end

    it 'skips objects that do not exist in the bucket' do
      blob.update!(key: 'users/abc')
      allow(object).to receive(:exists?).and_return(false)

      expect { subject.invoke }.to output("Finished\n").to_stdout
      expect(blob.reload.key).to eq 'users/abc'
    end

    it 'prints the error and continues when moving fails' do
      blob.update!(key: 'users/abc')
      allow(object).to receive(:move_to).and_raise(StandardError, 'boom')

      expect { subject.invoke }.to output(/Caught exception copying object users\/abc:\nboom\nFinished\n/).to_stdout
    end
  end

  context 'with no known storage' do
    it 'does nothing' do
      expect { subject.invoke }.not_to output.to_stdout
    end
  end
end
