# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditingFlagsChannel, type: :channel do
  let(:user) { create :user }
  let(:connection_user) { user }
  let!(:team) { create :team, :change_user_team, created_by: user }
  let!(:protocol) { create :protocol, :in_repository_draft, added_by: user, team: team }
  let!(:step) { create :step, protocol: protocol }
  let!(:step_text) { create :step_text, step: step }
  let!(:result_template) { create :result_template, protocol: protocol, user: user }
  let!(:result_text) { create :result_text, result: result_template }

  before do
    stub_connection current_user: connection_user
  end

  it 'confirms the subscription and streams for the subject' do
    subscribe(subject_type: 'StepText', subject_id: step_text.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(step_text)
  end

  it 'confirms the subscription and streams for a result text subject' do
    subscribe(subject_type: 'ResultText', subject_id: result_text.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(result_text)
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

  it 'rejects the subscription for a subject_type outside the allow-list' do
    subscribe(subject_type: 'Step', subject_id: step.id)

    expect(subscription).to be_rejected
  end

  it 'rejects the subscription when the subject does not exist' do
    subscribe(subject_type: 'StepText', subject_id: -1)

    expect(subscription).to be_rejected
  end

  context 'when the user has switched to another team since connecting' do
    let(:other_team) { create :team, :change_user_team, created_by: user }
    let(:connection_user) { User.find(other_team.created_by_id) }

    it 'confirms the subscription for a step text in the subject team' do
      subscribe(subject_type: 'StepText', subject_id: step_text.id)

      expect(connection_user.current_team).to eq other_team
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(step_text)
    end

    it 'confirms the subscription for a result text in the subject team' do
      subscribe(subject_type: 'ResultText', subject_id: result_text.id)

      expect(connection_user.current_team).to eq other_team
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(result_text)
    end
  end

  context 'when the user cannot read the subject' do
    let(:connection_user) { create :user }

    it 'rejects the subscription for a step text' do
      subscribe(subject_type: 'StepText', subject_id: step_text.id)

      expect(subscription).to be_rejected
    end

    it 'rejects the subscription for a result text' do
      subscribe(subject_type: 'ResultText', subject_id: result_text.id)

      expect(subscription).to be_rejected
    end
  end
end
