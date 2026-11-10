# frozen_string_literal: true

require 'rails_helper'

describe RepositoryStockZipExportJob, type: :job do
  it 'uses the stock consumption title for failure notifications' do
    expect(described_class.new.send(:failed_notification_title)).to eq(
      I18n.t('activejob.failure_notifiable_job.item_notification_title',
             item: I18n.t('activejob.failure_notifiable_job.items.stock_consumption'))
    )
  end
end
