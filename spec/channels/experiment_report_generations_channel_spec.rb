# frozen_string_literal: true

require 'rails_helper'

describe ExperimentReportGenerationsChannel, type: :channel do
  let(:user) { create(:user) }
  let(:experiment) { create(:experiment) }

  before { stub_connection current_user: user }

  it 'confirms the subscription and streams for the given experiment' do
    subscribe(experiment_id: experiment.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(experiment)
    expect(subscription).to have_stream_from("experiment_report_generations:#{experiment.to_gid_param}")
  end

  it 'does not stream for another experiment' do
    other = create(:experiment)
    subscribe(experiment_id: experiment.id)

    expect(subscription).not_to have_stream_for(other)
  end

  it 'delivers broadcasts made to the experiment' do
    subscribe(experiment_id: experiment.id)

    expect { described_class.broadcast_to(experiment, { 'done' => true }) }
      .to have_broadcasted_to(experiment).from_channel(described_class).with('done' => true)
  end

  it 'raises RecordNotFound for an unknown experiment id' do
    expect { subscribe(experiment_id: 0) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'unsubscribes cleanly' do
    subscribe(experiment_id: experiment.id)

    expect { unsubscribe }.to change { subscription.streams.size }.from(1).to(0)
  end

  it 'rejects a user without access to the experiment' do
    # bug: no permission check, any authenticated user can stream any experiment's report events
    pending 'bug: channel subscribes users who have no access to the experiment'
    subscribe(experiment_id: experiment.id)

    expect(subscription).to be_rejected
  end
end
