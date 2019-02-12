# frozen_string_literal: true

module ModelExporters
  class ProtocolExporter < ModelExporter
    def initialize(protocol_id)
      super()
      @protocol = Protocol.find(protocol_id)
    end

    def protocol
      {
        protocol: @protocol,
        protocol_protocol_keywords: @protocol.protocol_protocol_keywords,
        steps: @protocol.steps.map { |s| step(s) }
      }
    end

    def step(step)
      @assets_to_copy.push(step.assets.to_a) if step.assets.present?
      {
        step: step,
        checklists: step.checklists.map { |c| checklist(c) },
        step_comments: step.step_comments,
        step_assets: step.step_assets,
        assets: step.assets,
        step_tables: step.step_tables,
        tables: step.tables.map { |t| table(t) }
      }
    end
  end
end
