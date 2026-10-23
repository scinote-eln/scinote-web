# frozen_string_literal: true

require 'rails_helper'

describe SciFormHelper, type: :helper do
  let(:date_format) { '%-d.%-m.%Y' }
  let(:builder_object) { Struct.new(:published, :notes).new(nil, "line one\nline two\nline three") }
  let(:builder) { SciFormHelper::SciFormBuilder.new(:post, builder_object, helper, {}) }

  before do
    allow(I18n.backend).to receive(:date_format).and_return(date_format)
  end

  describe '#datetime_picker_format_date_only' do
    it 'converts the I18n date format into a Bootstrap date picker format' do
      expect(helper.datetime_picker_format_date_only).to eq 'D.M.YYYY'
    end

    it 'maps zero padded and long day, month and abbreviated month tokens' do
      allow(I18n.backend).to receive(:date_format).and_return('%d/%m/%Y %B %b')
      expect(helper.datetime_picker_format_date_only).to eq 'DD/MM/YYYY MMMM MMM'
    end

    it 'maps zero padded month and day tokens' do
      allow(I18n.backend).to receive(:date_format).and_return('%m-%d-%Y')
      expect(helper.datetime_picker_format_date_only).to eq 'MM-DD-YYYY'
    end
  end

  describe '#datetime_picker_format_date_only_vue' do
    it 'converts the I18n date format into a Vue (date-fns style) format' do
      expect(helper.datetime_picker_format_date_only_vue).to eq 'd.M.yyyy'
    end

    it 'maps zero padded and long tokens' do
      allow(I18n.backend).to receive(:date_format).and_return('%d.%m.%Y %B %b')
      expect(helper.datetime_picker_format_date_only_vue).to eq 'dd.MM.yyyy MMMM MMM'
    end
  end

  describe '#datetime_picker_format_full' do
    it 'appends the 24 hour time to the date only format' do
      expect(helper.datetime_picker_format_full).to eq 'D.M.YYYY HH:mm'
    end

    it 'does not modify the date only format' do
      helper.datetime_picker_format_full
      expect(helper.datetime_picker_format_date_only).to eq 'D.M.YYYY'
    end
  end

  describe '#datetime_picker_format_full_vue' do
    it 'appends the 24 hour time to the vue date format' do
      expect(helper.datetime_picker_format_full_vue).to eq 'd.M.yyyy HH:mm'
    end
  end

  describe SciFormHelper::SciFormBuilder do
    describe '#datetime_picker' do
      it 'renders a date only picker with a label derived from the attribute name' do
        html = builder.datetime_picker(:published)

        expect(html).to be_html_safe
        expect(html).to include("<label class='control-label required' for='post_published'>Published</label>")
        expect(html).to include("name='post[published]'", "id='post_published'")
        expect(html).to include("data-date-format='D.M.YYYY'")
        expect(html).to include("data-date-show-today-button='false'")
        expect(html).not_to include('input-group')
      end

      it 'uses the full date time format when time is requested and formats the value' do
        value = Time.zone.local(2024, 1, 15, 10, 30)
        html = builder.datetime_picker(:published, time: true, value: value)

        expect(html).to include("data-date-format='D.M.YYYY HH:mm'")
        expect(html).to include("value='15.1.2024 10:30'")
      end

      it 'renders a clear button and the today button when requested' do
        html = builder.datetime_picker(:published, clear: true, today: true, label: 'Date')

        expect(html).to include("<label class='control-label required' for='post_published'>Date</label>")
        expect(html).to include("<div class='input-group date'>")
        expect(html).to include("data-toggle='clear-date-time-picker' data-target='post_published'")
        expect(html).to include("data-date-show-today-button='true'")
      end

      it 'applies the custom style to the wrapping element' do
        html = builder.datetime_picker(:published, style: 'margin-top: 20px;')
        expect(html).to include("<div class='form-group' style='margin-top: 20px;'>")
      end

      it 'uses the current locale for the js locale attribute' do
        html = builder.datetime_picker(:published)
        expect(html).to include("data-date-locale='#{I18n.locale}'")
      end
    end

    describe '#smart_text_area' do
      it 'adds the smart-text-area class and derives rows from the object value' do
        html = builder.smart_text_area(:notes)

        expect(html).to include('smart-text-area')
        expect(html).to include('rows="3"')
      end

      it 'keeps the explicitly given rows' do
        html = builder.smart_text_area(:notes, rows: 7)
        expect(html).to include('rows="7"')
      end

      it 'adds the textarea-sm-present class for single line fields with explicit rows' do
        html = builder.smart_text_area(:notes, single_line: true, rows: 1)
        expect(html).to include('smart-text-area textarea-sm-present')
      end

      it 'adds the textarea-sm class for single line fields without rows' do
        empty = Struct.new(:notes).new(nil)
        html = SciFormHelper::SciFormBuilder.new(:post, empty, helper, {}).smart_text_area(:notes, single_line: true)
        expect(html).to include('smart-text-area textarea-sm')
        expect(html).not_to include('textarea-sm-present')
      end

      it 'does not add rows when the object has no value to count lines of' do
        empty = Struct.new(:notes).new(nil)
        empty_builder = SciFormHelper::SciFormBuilder.new(:post, empty, helper, {})
        html = empty_builder.smart_text_area(:notes)

        expect(html).not_to include('rows=')
      end

      it 'keeps the custom css class' do
        html = builder.smart_text_area(:notes, class: 'custom-class', rows: 2)
        expect(html).to include('custom-class smart-text-area')
      end
    end

    describe '#tiny_mce_editor' do
      it 'renders a textarea with the tinymce defaults and asset path' do
        html = builder.tiny_mce_editor(:notes)

        expect(html).to include('cols="120"', 'rows="10"')
        expect(html).to include("data-tinymce-asset-path=\"#{Rails.application.routes.url_helpers.tiny_mce_assets_path}\"")
      end

      it 'keeps the defaults for options the caller does not pass' do
        html = builder.tiny_mce_editor(:notes)
        expect(html).to include('cols="120"')
      end

      # bug: deep_merge! lets the tinymce defaults overwrite caller options (sci_form_helper.rb tiny_mce_editor)
      pending 'bug: caller rows option is overridden by the tinymce default' do
        html = builder.tiny_mce_editor(:notes, rows: 4)
        expect(html).to include('rows="4"')
      end
    end
  end
end
