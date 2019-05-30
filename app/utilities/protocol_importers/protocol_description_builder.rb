# frozen_string_literal: true

module ProtocolImporters
  class ProtocolDescriptionBuilder
    def self.generate(protocol_json)
      return '' unless protocol_json[:description]

      html_desc = ''
      html_desc = "<p>#{remove_html(protocol_json[:description][:body])}</p>" if protocol_json[:description][:body]
      html_desc += "<img src='#{protocol_json[:description][:image]}' /><br />" if protocol_json[:description][:image]
      html_desc += protocol_json[:description][:extra_content]&.map do |i|
        "<p>#{remove_html(i[:title])}: <br> #{remove_html(i[:body])}<p>"
      end&.join(' <br> ').to_s
      html_desc
    end

    def self.remove_html(string)
      ActionView::Base.full_sanitizer.sanitize(string)
    end
  end
end
