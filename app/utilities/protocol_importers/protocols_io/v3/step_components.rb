# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIO
    module V3
      class StepComponents
        AVAILABLE_COMPONENTS = {
          6 => :title,
          1 => :description
        }.freeze

        def self.get_component(id, components)
          if AVAILABLE_COMPONENTS.include?(id)
            components.find { |o| o[:type_id] == id }
          else
            raise ArgumentError
          end
        end

        def self.name(components)
          get_component(6, components)[:source][:title]
        end

        def self.description(components)
          get_component(1, components)[:source][:description]
        end
      end
    end
  end
end
