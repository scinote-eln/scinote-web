# frozen_string_literal: true

require 'rails_helper'

describe MyModuleReportGenerationsChannel, type: :channel do
  let(:user) { create(:user) }
  let(:my_module) { create(:my_module) }

  before { stub_connection current_user: user }

  it 'confirms the subscription and streams for the given my_module' do
    subscribe(my_module_id: my_module.id)

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(my_module)
    expect(subscription).to have_stream_from("my_module_report_generations:#{my_module.to_gid_param}")
  end

  it 'does not stream for another my_module' do
    other = create(:my_module)
    subscribe(my_module_id: my_module.id)

    expect(subscription).not_to have_stream_for(other)
  end

  it 'delivers broadcasts made to the my_module' do
    subscribe(my_module_id: my_module.id)

    expect { described_class.broadcast_to(my_module, { 'done' => true }) }
      .to have_broadcasted_to(my_module).from_channel(described_class).with('done' => true)
  end

  it 'raises RecordNotFound for an unknown my_module id' do
    expect { subscribe(my_module_id: 0) }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'unsubscribes cleanly' do
    subscribe(my_module_id: my_module.id)

    expect { unsubscribe }.to change { subscription.streams.size }.from(1).to(0)
  end

  it 'rejects a user without access to the my_module' do
    # bug: no permission check, any authenticated user can stream any my_module's report events
    pending 'bug: channel subscribes users who have no access to the my_module'
    subscribe(my_module_id: my_module.id)

    expect(subscription).to be_rejected
  end
end
