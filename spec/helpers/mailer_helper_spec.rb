# frozen_string_literal: true

require 'rails_helper'

describe MailerHelper, type: :helper do
  let(:host) { Rails.application.config.action_mailer.default_url_options[:host] }

  describe '#prepend_server_url_to_links' do
    it 'prepends the server url to relative paths' do
      result = helper.prepend_server_url_to_links('<a href="/projects/1">p</a>')
      expect(result).to eq "<a href=\"http://#{host}/projects/1\">p</a>"
    end

    it 'adds a slash when the path has none' do
      expect(helper.prepend_server_url_to_links('<a href="x">p</a>')).to include("http://#{host}/x")
    end

    it 'does not prefix links that already start with the host' do
      html = "<a href=\"#{host}/a\">p</a>"
      expect(helper.prepend_server_url_to_links(html)).to eq html
    end

    it 'leaves text without links unchanged' do
      expect(helper.prepend_server_url_to_links('<b>hi</b>')).to eq '<b>hi</b>'
    end

    it 'rewrites every link' do
      result = helper.prepend_server_url_to_links('<a href="/a">1</a><a href="/b">2</a>')
      expect(result).to include("http://#{host}/a").and include("http://#{host}/b")
    end
  end
end
