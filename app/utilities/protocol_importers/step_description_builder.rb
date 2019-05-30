# frozen_string_literal: true

module ProtocolImporters
  class StepDescriptionBuilder
    def self.generate(step_json)
      return '' unless step_json[:description]

      html_description = ''
      html_description = "<p>#{remove_html(step_json[:description][:body])}</p>" if step_json[:description][:body]

      # Add components from JSON
      html_description += step_json[:description][:components]&.inject('') do |html_string, component|
        sanitized_component = component.except(:type)
        sanitized_component[:body] = remove_html(component[:body]) if component[:body]

        html_string + ApplicationController
                      .renderer
                      .render(template: "templates/protocols_import/step_description/#{component[:type]}",
                                layout: false,
                                assigns: { item: sanitized_component })
      end.to_s

      # Add extra content from JSON
      html_description += step_json[:description][:extra_content]&.map do |i|
        "<p>#{remove_html(i[:title])}: <br> #{remove_html(i[:body])}<p>"
      end&.join(' <br> ').to_s

      html_description
    end

    def self.remove_html(string)
      ActionView::Base.full_sanitizer.sanitize(string)
    end
  end
end
