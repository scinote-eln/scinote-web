# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportTemplatePreviewChannel, type: :channel do
  let(:user) { create(:user) }
  let(:protocol) { create(:protocol) }
  let(:report_template) { create(:report_template, subject: protocol) }
  let(:warden) { instance_double("Warden::Proxy") }

  before do
    allow(warden).to receive(:user).and_return(user)

    stub_connection current_user: user, env: { 'warden' => warden }
  end

  context 'when the user can read the protocol' do
    before do
      without_partial_double_verification do
        allow_any_instance_of(described_class).to receive(:can_read_protocol_in_module?).and_return(true)
        allow_any_instance_of(described_class).to receive(:can_read_protocol_in_repository?).and_return(false)
      end
    end

    it 'subscribes and streams for the report template' do
      subscribe(report_template_id: report_template.id)

      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(report_template)
    end

    it 'transmits the current preview status on subscribe' do
      allow_any_instance_of(ReportTemplate).to receive(:preview_status).and_return('processing')

      subscribe(report_template_id: report_template.id)

      expect(transmissions.last['status']).to eq('processing')
    end

    it 'transmits failed on subscribe when the preview failed permanently' do
      allow_any_instance_of(ReportTemplate).to receive(:preview_status).and_return('failed')

      subscribe(report_template_id: report_template.id)

      expect(transmissions.last['status']).to eq('failed')
    end

    it 'transmits ready on subscribe when the preview finished before the client subscribed' do
      allow_any_instance_of(ReportTemplate).to receive(:preview_status).and_return('ready')

      subscribe(report_template_id: report_template.id)

      expect(transmissions.last['status']).to eq('ready')
    end

    it 'receives broadcasts for the subscribed report template' do
      subscribe(report_template_id: report_template.id)

      expect do
        described_class.broadcast_to(report_template, status: 'ready')
      end.to have_broadcasted_to(report_template).from_channel(described_class).with(status: 'ready')
    end

    it 'does not receive broadcasts for another report template' do
      other_report_template = create(:report_template, subject: protocol)
      subscribe(report_template_id: report_template.id)

      expect(subscription).not_to have_stream_for(other_report_template)
    end
  end

  context 'when the user cannot read the protocol' do
    before do
      without_partial_double_verification do
        allow_any_instance_of(described_class).to receive(:can_read_protocol_in_module?).and_return(false)
        allow_any_instance_of(described_class).to receive(:can_read_protocol_in_repository?).and_return(false)
      end
    end

    it 'rejects the subscription' do
      subscribe(report_template_id: report_template.id)

      expect(subscription).to be_rejected
    end
  end

  context 'when the report template does not exist' do
    it 'rejects the subscription' do
      subscribe(report_template_id: -1)

      expect(subscription).to be_rejected
    end
  end
end
