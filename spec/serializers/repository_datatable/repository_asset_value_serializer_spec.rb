# frozen_string_literal: true

require 'rails_helper'

describe RepositoryDatatable::RepositoryAssetValueSerializer do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:repository) { create :repository, team: team, created_by: user }
  let(:routes) { Rails.application.routes.url_helpers }
  let(:asset) { create :asset, team: team }

  def attach_file(record, filename, content_type = nil)
    File.open(Rails.root.join('spec/fixtures/files/test.jpg')) do |file|
      record.file.attach(io: file, filename: filename, content_type: content_type)
    end
    record
  end

  def value_for(record = asset)
    value_object = build :repository_asset_value, asset: record
    described_class.new(value_object, scope: { repository: repository, options: {} }).value
  end

  it 'exposes the asset id, download and preview urls and the file name' do
    attach_file(asset, 'lab-notes.jpg')
    value = value_for

    expect(value).to include(
      id: asset.id,
      preview_url: routes.asset_file_preview_path(asset),
      file_name: 'lab-notes.jpg',
      snapshot: nil
    )
    expect(value[:url]).to start_with('/rails/active_storage/blobs')
    expect(value[:url]).to include('disposition=attachment')
  end

  it 'provides a medium preview url for previewable images' do
    attach_file(asset, 'lab-notes.jpg')

    expect(value_for[:medium_preview_url]).to include('/rails/active_storage/representations/')
  end

  it 'provides no medium preview url for files that cannot be previewed' do
    attach_file(asset, 'archive.zip', 'application/zip')
    allow(asset).to receive(:previewable?).and_return(false)

    expect(value_for[:medium_preview_url]).to be false
  end

  it 'uses the spreadsheet icon for table files' do
    attach_file(asset, 'budget.xlsx')

    expect(value_for[:icon_html]).to eq 'file-excel'
  end

  it 'uses the word icon for text documents' do
    attach_file(asset, 'protocol.docx')

    expect(value_for[:icon_html]).to eq 'file-word'
  end

  it 'has no special icon for images' do
    attach_file(asset, 'lab-notes.jpg')

    expect(value_for[:icon_html]).to be_nil
  end

  it 'escapes html in the file name' do
    attach_file(asset, 'Q&A <draft>.jpg')

    expect(value_for[:file_name]).to eq 'Q&amp;A &lt;draft&gt;.jpg'
  end

  it 'passes the snapshot flag of the asset' do
    attach_file(asset, 'lab-notes.jpg')
    asset.snapshot = true

    expect(value_for[:snapshot]).to be true
  end

  it 'logs the error and does not raise when the asset cannot be rendered' do
    attach_file(asset, 'lab-notes.jpg')
    allow(asset).to receive(:file_name).and_raise(StandardError, 'boom')
    expect(Rails.logger).to receive(:error).with('boom')

    expect { value_for }.not_to raise_error
  end

  it 'returns no value when the asset cannot be rendered' do
    attach_file(asset, 'lab-notes.jpg')
    allow(asset).to receive(:file_name).and_raise(StandardError, 'boom')
    allow(Rails.logger).to receive(:error).and_call_original

    pending 'bug: a failed asset rendering returns the logger result (true) as the cell value'
    expect(value_for).to be_nil
  end
end
