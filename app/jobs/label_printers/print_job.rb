# frozen_string_literal: true

module LabelPrinters
  class PrintJob < ApplicationJob
    queue_as :high_priority

    def perform(label_printer, payload)
      case label_printer.type_of
      when 'fluics'
        LabelPrinters::Fluics::ApiClient.new(
          label_printer.fluics_api_key
        ).print(label_printer.fluics_lid, payload)
      end
    end
  end
end
