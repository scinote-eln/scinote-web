# frozen_string_literal: true

require 'rails_helper'

describe LabelPrinters::PrintJob, type: :job do
  let(:printer) do
    LabelPrinter.create!(name: 'Printer 1', type_of: :fluics, language_type: :zpl,
                         fluics_api_key: 'key-1', fluics_lid: 'LID1', status: :busy)
  end
  let(:api_client) { instance_double(LabelPrinters::Fluics::ApiClient) }

  before do
    allow(LabelPrinters::Fluics::ApiClient).to receive(:new).with('key-1').and_return(api_client)
  end

  def build_job(copies)
    job = described_class.new(printer, 'ZPL-PAYLOAD', copies)
    printer.update!(current_print_job_ids: [job.job_id, 'other-job'] + [job.job_id] * (copies - 1))
    job
  end

  it 'prints every copy, removes the finished job ids from the queue and leaves the printer ready' do
    allow(api_client).to receive(:print).with('LID1', 'ZPL-PAYLOAD').and_return({ 'status' => 'OK' })
    job = build_job(2)

    job.perform_now

    expect(api_client).to have_received(:print).twice
    printer.reload
    expect(printer.status).to eq 'ready'
    expect(printer.current_print_job_ids).to eq ['other-job']
  end

  it 'stops printing and stores the mapped status when the printer reports a problem' do
    allow(api_client).to receive(:print).and_return({ 'status' => 'ERROR', 'printerStatus' => '01' })
    job = build_job(3)

    job.perform_now

    expect(api_client).to have_received(:print).once
    printer.reload
    expect(printer.status).to eq 'out_of_labels'
    expect(printer.current_print_job_ids).to include(job.job_id)
  end

  it 'maps unknown printer status to error' do
    allow(api_client).to receive(:print).and_return({ 'status' => 'ERROR', 'printerStatus' => '99' })

    build_job(1).perform_now

    expect(printer.reload.status).to eq 'error'
  end

  it 'marks the printer unreachable when no final state is reached' do
    allow(api_client).to receive(:print).and_return({ 'status' => 'ERROR', 'printerStatus' => '50' })

    build_job(1).perform_now

    expect(printer.reload.status).to eq 'unreachable'
  end

  it 'sets the printer status to error when the api client raises' do
    allow(api_client).to receive(:print).and_raise(StandardError, 'network down')

    expect { build_job(1).perform_now }.not_to raise_error

    expect(printer.reload.status).to eq 'error'
  end
end
