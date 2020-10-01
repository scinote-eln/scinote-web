# frozen_string_literal: true

require 'rails_helper'

describe Reports::Docx do
  let(:user) { create :user }
  let(:team) { create :team }
  let(:docx) { double('docx') }
  let(:report) { described_class.new({}.to_json, docx, user: user, team: team, scinote_url: 'scinote.test') }

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
      expect(report.send(:list_element, xml_elements)).to be == result
    end
  end
end
