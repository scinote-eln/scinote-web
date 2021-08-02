# frozen_string_literal: true

module LabelPrinters
  class PrintJob < ApplicationJob
    MAX_STATUS_UPDATES = 10

    queue_as :high_priority

    discard_on(StandardError) do |job, _error|
      label_printer = job.arguments.first
      label_printer.update!(status: :error)
    end

    def perform(label_printer, payload)
      case label_printer.type_of
      when 'fluics'
        api_client = LabelPrinters::Fluics::ApiClient.new(
          label_printer.fluics_api_key
        )

        api_client.print(label_printer.fluics_lid, payload)

        # wait for FLUICS printer to stop being busy
        MAX_STATUS_UPDATES.times do
          status =
            LabelPrinter::FLUICS_STATUS_MAP[
              api_client.status(label_printer.fluics_lid).dig('printerState', 'printerStatus')
            ]
          label_printer.update!(status: status)

          break if status == :ready

          sleep 5
        end
      end

      # mark as unreachable if no final state is reached
      label_printer.update!(status: :unreachable) unless label_printer.status.in? %w(ready out_of_labels)

      label_printer.with_lock do
        label_printer.current_print_job_ids.delete(job_id)
        label_printer.save!
      end
    end
  end
end
