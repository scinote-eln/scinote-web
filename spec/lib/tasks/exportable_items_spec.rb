# frozen_string_literal: true

require 'rails_helper'

describe 'exportable_items:cleanup' do
  include_context 'rake file loaded once', 'exportable_items'

  # With Delayed::Worker.delay_jobs = false the after_create hook would delete every export at once.
  before { allow(ZipExport).to receive(:delay).and_return(double(delete_expired_export: nil)) }

  let!(:old_export) { create(:zip_export).tap { |z| z.update_column(:created_at, (Constants::EXPORTABLE_ZIP_EXPIRATION_DAYS + 1).days.ago) } }
  let!(:fresh_export) { create(:zip_export).tap { |z| z.update_column(:created_at, (Constants::EXPORTABLE_ZIP_EXPIRATION_DAYS - 1).days.ago) } }

  it 'removes only exports older than the expiration period' do
    expect { rake_task('exportable_items:cleanup').invoke }.to output(/All exportable zip files older than/).to_stdout

    expect(ZipExport.exists?(old_export.id)).to be(false)
    expect(ZipExport.exists?(fresh_export.id)).to be(true)
  end

  it 'names the expiration limit in the output' do
    expect { rake_task('exportable_items:cleanup').invoke }.to output(/older than '.+' have been removed/).to_stdout
  end
end
