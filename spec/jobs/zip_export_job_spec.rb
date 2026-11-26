# frozen_string_literal: true

require 'rails_helper'

describe ZipExportJob, type: :job do
  let(:user) { create :user }

  before { ZipExport.skip_callback(:create, :after, :self_destruct) }
  after { ZipExport.set_callback(:create, :after, :self_destruct) }

  let(:subclass) do
    Class.new(described_class) do
      def self.name
        'TestZipExportJob'
      end

      private

      def fill_content(dir, _params)
        File.write("#{dir}/hello.txt", 'hi')
      end
    end
  end

  let(:format_before) { I18n.backend.date_format }

  it 'zips the content, attaches it, notifies the user with a download link and removes temp files' do
    format_before
    expect { subclass.perform_now(user_id: user.id) }.to change(ZipExport, :count).by(1)
                                                     .and change(Notification, :count).by(1)

    export = ZipExport.last
    expect(export.zip_file).to be_attached
    expect(export.zip_file.filename.to_s).to match(/\Aexport_.*\.zip\z/)
    message = Notification.last.to_notification.message
    expect(message).to include("data-id='#{export.id}'").and include(export.zip_file_name)
    expect(Dir.glob(Rails.root.join('tmp/temp_zip_*'))).to be_empty
    expect(I18n.backend.date_format).to eq format_before
  end

  it 'swallows missing file errors and logs them' do
    allow(Rails.logger).to receive(:error)
    allow_any_instance_of(ZipExport).to receive(:zip!).and_raise(Errno::ENOENT, 'gone')

    expect { subclass.perform_now(user_id: user.id) }.not_to raise_error

    expect(Rails.logger).to have_received(:error).with(/gone/)
    expect(Notification.count).to eq 0
  end

  it 'requires subclasses to implement fill_content' do
    job = described_class.new(user_id: user.id)
    job.enqueued_at = Time.current

    expect { job.perform_now }.to raise_error(NotImplementedError)
  end
end
