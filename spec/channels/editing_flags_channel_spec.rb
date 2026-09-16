# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditingFlagsChannel, type: :channel do
  let(:user) { create :user }
  let(:step_text) { create :step_text }

  before do
    stub_connection current_user: user
  end

  it 'confirms the subscription and streams for the subject' do
    subscribe(subject_type: 'StepText', subject_id: step_text.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(step_text)
  end

  it 'delivers broadcasts to subscribers' do
    subscribe(subject_type: 'StepText', subject_id: step_text.id)

    expect do
      EditingFlagsChannel.broadcast_to(step_text, action: 'create')
    end.to have_broadcasted_to(step_text).from_channel(EditingFlagsChannel).with(hash_including('action' => 'create'))
  end

  it 'rejects the subscription for an unresolvable subject_type' do
    subscribe(subject_type: 'NotARealModel', subject_id: step_text.id)

    expect(subscription).to be_rejected
  end

  it 'rejects the subscription when the subject does not exist' do
    subscribe(subject_type: 'StepText', subject_id: -1)

    expect(subscription).to be_rejected
  end
end
