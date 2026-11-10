# frozen_string_literal: true

require 'rails_helper'

describe ProjectsJsonExportJob, type: :job do
  let(:user) { create :user }

  it 'generates the data and posts it using the service' do
    service = instance_double(ProjectsJsonExportService, generate_data: true, post_request: true)
    allow(ProjectsJsonExportService).to receive(:new).with([1, 2], 'http://cb', user).and_return(service)

    described_class.perform_now([1, 2], 'http://cb', user.id)

    expect(service).to have_received(:generate_data).ordered
    expect(service).to have_received(:post_request).ordered
  end

  it 'raises when the user does not exist' do
    expect { described_class.perform_now([1], 'http://cb', -1) }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
