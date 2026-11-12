# frozen_string_literal: true

require 'rails_helper'

describe ActiveStorage::PreviewJob, type: :job do
  let(:asset) { create :asset, file_processing: true }
  let(:blob) { asset.file.blob }
  let(:preview) { double('preview', variation: double('variation', transformations: { resize: 1 })) }
  let(:variant) { double('variant', processed: preview) }

  it 'processes the medium and large previews and clears the processing flag' do
    allow_any_instance_of(Asset).to receive(:medium_preview).and_return(variant)
    allow_any_instance_of(Asset).to receive(:large_preview).and_return(variant)

    described_class.perform_now(blob.id)

    expect(variant).to have_received(:processed).twice
    expect(asset.reload.file_processing).to be false
  end

  it 'flags the blob when generation fails and stops processing' do
    allow_any_instance_of(Asset).to receive(:medium_preview).and_raise(StandardError, 'vips failed')
    allow(Rails.logger).to receive(:error)

    expect { described_class.perform_now(blob.id) }.not_to raise_error

    expect(blob.reload.metadata['preview_failed']).to be true
    expect(asset.reload.file_processing).to be false
    expect(Rails.logger).to have_received(:error).with(/Couldn't generate preview for Blob with id: #{blob.id}.*vips failed/m)
  end

  it 'discards the job when the blob does not exist' do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end

  it 'retries on integrity errors' do
    allow_any_instance_of(Asset).to receive(:medium_preview).and_raise(ActiveStorage::IntegrityError)
    ActiveJob::Base.queue_adapter = :test

    expect { described_class.perform_now(blob.id) }.to have_enqueued_job(described_class).with(blob.id)
  end
end
