# frozen_string_literal: true

require 'rails_helper'

describe Reports::HtmlToWordConverter do
  let(:user) { create :user }
  let(:team) { create :team, created_by: user }
  let(:docx) { double('docx') }
  let(:report) { described_class.new(docx) }

  describe 'html_list' do
    let(:text) do
      '<body><ul><li>1</li><li>2<ul><li>one</li><li>two<ol><li>uno</li><li>due</li>'\
      '</ol></li></ul></li><li>3</li><li>4</li><li>5</li></ul></body>'
    end
    let(:xml_elements) { Nokogiri::HTML(text).css('body').children.first }
    let(:result) do
      {
        type: 'ul',
        data: [%w(1),
               ['2', { type: 'ul', data: [%w(one), ['two', { type: 'ol', data: [%w(uno), %w(due)] }]] }],
               %w(3), %w(4), %w(5)]
      }
    end
    it '' do
      expect(report.__send__(:list_element, xml_elements)).to be == result
    end
  end

  describe '.tiny_mce_table_element' do
    let(:text) do
      # rubocop:disable Layout/LineLength
      '<body><table style="border-collapse: collapse; width: 100%; height: 28px;" border="1" data-mce-style="border-collapse: collapse; width: 100%; height: 28px;"><tbody><tr style="height: 10px;"><td style="width: 50%; height: 10px;">1</td><td style="width: 50%; height: 10px;">2</td></tr><tr style="height: 18px;"><td style="width: 50%; height: 18px;">3</td><td style="width: 50%; height: 18px;">4</td></tr></tbody></table></body>'
      # rubocop:enable Layout/LineLength
    end
    let(:xml_elements) { Nokogiri::HTML(text).css('body').children.first }
    let(:result) do
      {
        data: [
          {
            data: [
              [{ children: [{ style: {}, type: 'text', value: '1' }], type: 'p' }],
              [{ children: [{ style: {}, type: 'text', value: '2' }], type: 'p' }]
            ],
            type: 'tr'
          },
          {
            data: [
              [{ children: [{ style: {}, type: 'text', value: '3' }], type: 'p' }],
              [{ children: [{ style: {}, type: 'text', value: '4' }], type: 'p' }]
            ],
            type: 'tr'
          }
        ],
        type: 'table'
      }
    end

    it '' do
      expect(report.__send__(:tiny_mce_table_element, xml_elements)).to be == result
    end
  end
end
