# frozen_string_literal: true

require 'rails_helper'

describe 'fonts:convert_to_base64' do
  include_context 'rake once'

  let(:main) { TOPLEVEL_BINDING.receiver }
  let(:css_path) { Rails.root.join('app/assets/stylesheets/reports_pdf_icons.sass.scss') }
  let(:icons_path) { Rails.root.join('vendor/assets/stylesheets/fonts/SN-icon-font.woff2') }
  let(:written) { StringIO.new }

  before do
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(css_path, 'w').and_yield(written)
  end

  context 'when the icon font exists' do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(icons_path).and_return(true)
      allow(main).to receive(:`).with("base64 -i #{icons_path}").and_return("QUJD\nREVG\n")
      allow(Rails.logger).to receive(:info)
    end

    it 'writes a font-face with the single-line base64 content and logs it' do
      subject.invoke

      expect(written.string).to include('font-family: "SN-icon-font"')
      expect(written.string).to include('src: url(data:font/woff2;base64,QUJDREVG);')
      expect(Rails.logger).to have_received(:info).with(/converted to base64 and written to #{Regexp.escape(css_path.to_s)}/)
    end
  end

  context 'when the icon font is missing' do
    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(icons_path).and_return(false)
      allow(Rails.logger).to receive(:warn)
    end

    it 'logs a warning and writes nothing' do
      subject.invoke

      expect(Rails.logger).to have_received(:warn).with("Icon font file not found at #{icons_path}")
      expect(File).not_to have_received(:open).with(css_path, 'w')
    end
  end
end
