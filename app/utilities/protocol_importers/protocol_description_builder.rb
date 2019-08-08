# frozen_string_literal: true

module ProtocolImporters
  class ProtocolDescriptionBuilder
    def self.generate(protocol_json)
      return '' unless protocol_json[:description]

      html_string = ApplicationController
                    .renderer
                    .render(template: 'protocol_importers/templates/protocol_description',
                            layout: false,
                            assigns: { description: protocol_json[:description] })
      html_string
    end
  end
end
