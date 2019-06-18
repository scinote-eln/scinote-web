# frozen_string_literal: true

module ProtocolImporters
  class StepDescriptionBuilder
    def self.generate(step_json)
      return '' unless step_json[:description]

      step_json[:description][:body] = TablesBuilder.remove_tables_from_html(step_json[:description][:body])
      html_string = ApplicationController
                    .renderer
                    .render(template: 'protocol_importers/templates/step_description',
                            layout: false,
                            assigns: { step_description: step_json[:description] })
      html_string
    end
  end
end
