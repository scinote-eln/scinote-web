# frozen_string_literal: true

require 'rails_helper'

describe CleanupUserSettingsJob, type: :job do
  let!(:user) { create :user }
  let!(:other_user) { create :user }

  before do
    user.update!(settings: user.settings.merge('task_step_states' => { '12' => true, '13' => false }))
    other_user.update!(settings: other_user.settings.merge('results_order' => { '99' => 'asc' }))
  end

  it 'removes the record from the given settings key of every user' do
    described_class.perform_now('task_step_states', 12)

    expect(user.reload.settings['task_step_states']).to eq('13' => false)
    expect(other_user.reload.settings['results_order']).to eq('99' => 'asc')
  end

  it 'rejects an unknown record type' do
    expect { described_class.perform_now('users', 1) }.to raise_error(ArgumentError, 'Invalid record_type')
  end

  it 'rejects a non numeric record id' do
    expect { described_class.perform_now('results_order', "1' OR 1=1") }
      .to raise_error(ArgumentError, 'Invalid record_id')
  end
end
