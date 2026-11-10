# frozen_string_literal: true

require 'rails_helper'

describe ApplicationJob, type: :job do
  describe '.status' do
    def delayed_job(job_id, attrs = {})
      Delayed::Job.create!({ handler: "--- !ruby/object:Foo\njob_id: #{job_id}\n", queue: 'default' }.merge(attrs))
    end

    it 'is done when no delayed job exists' do
      expect(described_class.status('no-such-id')).to eq :done
    end

    it 'is pending for an unlocked job' do
      delayed_job('abc-1')
      expect(described_class.status('abc-1')).to eq :pending
    end

    it 'is running for a locked job' do
      delayed_job('abc-2', locked_at: Time.current)
      expect(described_class.status('abc-2')).to eq :running
    end

    it 'is failed for a job with failed_at' do
      delayed_job('abc-3', failed_at: Time.current, locked_at: Time.current)
      expect(described_class.status('abc-3')).to eq :failed
    end
  end

  it 'is discarded on deserialization errors' do
    expect(described_class.rescue_handlers.map(&:first)).to include('ActiveJob::DeserializationError')
  end
end
