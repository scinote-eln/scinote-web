# frozen_string_literal: true

module ProtocolImporters
  module ProtocolsIo
    module V3
      class StepComponents
        AVAILABLE_COMPONENTS = {
          1 => :description,
          3 => :amount,
          4 => :duration,
          6 => :title,
          7 => :link,
          8 => :software,
          9 => :dataset,
          15 => :command,
          17 => :result,
          19 => :safety,
          20 => :reagents,
          22 => :gotostep,
          23 => :file,
          24 => :temperature,
          25 => :concentration,
          26 => :notes
        }.freeze

        DESCRIPTION_COMPONENTS = AVAILABLE_COMPONENTS.slice(3, 4, 7, 8, 9, 15, 17, 19, 20, 22, 24, 25, 26).freeze

        def self.get_component(id, components)
          if AVAILABLE_COMPONENTS.include?(id)
            components.find { |o| o[:type_id] == id }
          else
            raise ArgumentError
          end
        end

        def self.name(components)
          get_component(6, components)&.dig(:source, :title)
        end

        def self.description(components)
          get_component(1, components)&.dig(:source, :description)
        end

        def self.description_components(components)
          description_components = components.select { |c| DESCRIPTION_COMPONENTS.include?(c[:type_id]) }

          description_components.map do |dc|
            build_desc_component dc
          end.compact
        end

        def self.attachments(components)
          components.select { |c| c[:type_id] == 23 }.map do |cc|
            # Original name can be empty, so just use source
            name = cc.dig(:source, :original_name) || cc.dig(:source, :source).split('/')[-1]

            {
              url: cc.dig(:source, :source),
              name: name
            }
          end
        end

        def self.build_desc_component(desc_component)
          case AVAILABLE_COMPONENTS[desc_component[:type_id]]
          when :amount
            {
              type: 'amount',
              value: desc_component.dig(:source, :amount),
              unit: desc_component.dig(:source, :unit),
              name: desc_component.dig(:source, :title)
            }
          when :duration
            {
              type: 'duration',
              value: desc_component.dig(:source, :duration),
              name: desc_component.dig(:source, :title)
            }
          when :link
            {
              type: 'link',
              source: desc_component.dig(:source, :link)
            }
          when :software
            {
              type: 'software',
              name: desc_component.dig(:source, :name),
              source: desc_component.dig(:source, :link),
              details: {
                repository_link: desc_component.dig(:source, :repository),
                developer: desc_component.dig(:source, :developer),
                os_name: desc_component.dig(:source, :os_name)
              }
            }
          when :command
            {
              type: 'command',
              software_name: desc_component.dig(:source, :name),
              command: desc_component.dig(:source, :command),
              details: {
                os_name: desc_component.dig(:source, :os_name)
              }
            }
          when :result
            {
              type: 'result',
              body: desc_component.dig(:source, :body)
            }
          when :safety
            {
              type: 'warning',
              body: desc_component.dig(:source, :body),
              details: {
                link: desc_component.dig(:source, :link)
              }
            }
          when :reagents
            {
              type: 'reagent',
              name: desc_component.dig(:source, :name),
              link: desc_component.dig(:source, :url),
              details: {
                catalog_number: desc_component.dig(:source, :sku),
                linear_formula: desc_component.dig(:source, :linfor),
                mol_weight: desc_component.dig(:source, :mol_weight)
              }
            }
          when :gotostep
            {
              type: 'gotostep',
              value: desc_component.dig(:source, :title),
              step_id: desc_component.dig(:source, :step_guid)
            }
          when :temperature
            {
              type: 'temperature',
              value: desc_component.dig(:source, :temperature),
              unit: desc_component.dig(:source, :unit),
              name: desc_component.dig(:source, :title)
            }
          when :concentration
            {
              type: 'concentration',
              value: desc_component.dig(:source, :concentration),
              unit: desc_component.dig(:source, :unit),
              name: desc_component.dig(:source, :title)
            }
          when :notes
            {
              type: 'note',
              author: desc_component.dig(:source, :creator, :name),
              body: desc_component.dig(:source, :body)
            }
          when :dataset
            {
              type: 'dataset',
              name: desc_component.dig(:source, :name),
              source: desc_component.dig(:source, :link)
            }
          end
        end
      end
    end
  end
end
