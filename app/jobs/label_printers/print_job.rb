# frozen_string_literal: true

module LabelPrinters
  class PrintJob < ApplicationJob
    queue_as :high_priority

    def perform(label_printer, payload)
      case label_printer.type_of
      when 'fluics'
        api_client = LabelPrinters::Fluics::ApiClient.new(
          label_printer.fluics_api_key
        )

        api_client.print(label_printer.fluics_lid, payload)

        # wait for FLUICS printer to stop being busy
        sleep(5) while api_clinet.status(label_printer.fluics_lid).dig('printerState', 'printerStatus') != '00'
      end
    end
  end
end
