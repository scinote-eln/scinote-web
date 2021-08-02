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
        loop do
          status =
            LabelPrinters::FLUICS_STATUS_MAP(
              api_client.status(label_printer.fluics_lid).dig('printerState', 'printerStatus')
            )
          label_printer.update!(status: status)

          break if status == :ready

          sleep 5
        end
      end

      label_printer.with_lock do
        label_printer.current_print_job_ids.delete(job_id)
        label_printer.save!
      end
    end
  rescue StandardError => e
    label_printer.update(status: :error)
    raise e
  end
end
